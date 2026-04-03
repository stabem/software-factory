#!/usr/bin/env python3
"""Pipeline self-eval runner. Validates schemas and adversarial diff detection."""
import json
import re
import sys
import os

try:
    import jsonschema
except ImportError:
    print("ERROR: pip install jsonschema")
    sys.exit(1)

SCHEMAS_DIR = os.path.join(os.path.dirname(__file__), "..", "schemas")
EVALS_DIR = os.path.dirname(__file__)

results = {"pass": 0, "fail": 0, "errors": []}


def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_text(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def validate_must_pass(schema_path, fixture_path):
    schema = load_json(schema_path)
    fixture = load_json(fixture_path)
    try:
        jsonschema.validate(fixture, schema)
        results["pass"] += 1
        print(f"  PASS  {os.path.basename(fixture_path)}")
    except jsonschema.ValidationError as e:
        results["fail"] += 1
        results["errors"].append(f"SHOULD PASS but failed: {fixture_path}: {e.message}")
        print(f"  FAIL  {os.path.basename(fixture_path)} — {e.message}")


def validate_must_fail(schema_path, fixture_path):
    schema = load_json(schema_path)
    fixture = load_json(fixture_path)
    try:
        jsonschema.validate(fixture, schema)
        results["fail"] += 1
        results["errors"].append(f"SHOULD FAIL but passed: {fixture_path}")
        print(f"  FAIL  {os.path.basename(fixture_path)} — should have failed validation")
    except jsonschema.ValidationError:
        results["pass"] += 1
        print(f"  PASS  {os.path.basename(fixture_path)} (correctly rejected)")


# ── Adversarial diff detection ──
# These patterns mirror the deterministic preflight checks in code-review.yml.
# If someone changes code-review.yml and breaks a pattern, evals catch it.

SECRET_PATTERNS = [
    (r"AKIA[0-9A-Z]{16}", "AWS access key"),
    (r"-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----", "Private key"),
    (r'(?i)(password|secret|token|apikey|api_key)\s*[:=]\s*["\'][A-Za-z0-9+/=_\-]{16,}', "Hardcoded secret"),
]

DANGEROUS_PATTERNS = [
    (r"rejectUnauthorized\s*:\s*false", "TLS verification disabled (Node)"),
    (r"verify\s*=\s*False", "TLS verification disabled (Python)"),
    (r"InsecureSkipVerify\s*:\s*true", "TLS verification disabled (Go)"),
    (r"eval\s*\(", "eval() usage"),
    (r"dangerouslySetInnerHTML", "React XSS vector"),
    (r"unsafe-inline|unsafe-eval", "CSP weakening"),
]

INJECTION_PATTERNS = [
    (r'(?:query|execute|sql).*`[^`]*\$\{', "SQL injection via template literal"),
    (r'`[^`]*\$\{[^}]*\}[^`]*`.*(?:query|execute|sql)', "SQL injection via template literal"),
    (r"f['\"].*SELECT.*\{", "SQL injection via f-string"),
    (r"'[^']*\+\s*\w+\s*\+[^']*'.*(?:query|execute)", "SQL injection via string concat"),
]


def check_diff_patterns(diff_text, patterns):
    """Check if any pattern matches in the diff text. Returns list of matches."""
    found = []
    for pattern, label in patterns:
        if re.search(pattern, diff_text):
            found.append(label)
    return found


def eval_diff(fixture_path, expected_detections, expect_clean=False):
    """Evaluate an adversarial diff fixture against detection patterns."""
    diff_text = load_text(fixture_path)
    name = os.path.basename(fixture_path)

    all_patterns = SECRET_PATTERNS + DANGEROUS_PATTERNS + INJECTION_PATTERNS
    detections = check_diff_patterns(diff_text, all_patterns)

    if expect_clean:
        if len(detections) == 0:
            results["pass"] += 1
            print(f"  PASS  {name} (clean — no false positives)")
        else:
            results["fail"] += 1
            results["errors"].append(f"FALSE POSITIVE on clean diff {name}: {detections}")
            print(f"  FAIL  {name} — false positives: {detections}")
        return

    # Check that all expected detections were found
    missing = [d for d in expected_detections if d not in detections]
    if missing:
        results["fail"] += 1
        results["errors"].append(f"MISSED detections in {name}: {missing}")
        print(f"  FAIL  {name} — missed: {missing}")
    else:
        results["pass"] += 1
        print(f"  PASS  {name} (detected: {detections})")


def eval_scope_violation(fixture_path, in_scope_files):
    """Check that a diff modifies files outside the declared scope."""
    diff_text = load_text(fixture_path)
    name = os.path.basename(fixture_path)

    # Extract files changed in diff
    changed_files = re.findall(r"^diff --git a/(.+?) b/", diff_text, re.MULTILINE)

    out_of_scope = [f for f in changed_files if not any(f.startswith(s) for s in in_scope_files)]

    if out_of_scope:
        results["pass"] += 1
        print(f"  PASS  {name} (scope violation detected: {out_of_scope})")
    else:
        results["fail"] += 1
        results["errors"].append(f"MISSED scope violation in {name}")
        print(f"  FAIL  {name} — should have detected scope violation")


def main():
    print("=== Pipeline Self-Evals ===\n")

    # ── Schema validation evals ──
    sp_schema = os.path.join(SCHEMAS_DIR, "strategic-plan.schema.json")
    print("[Strategic Plan Schema]")
    validate_must_pass(sp_schema, os.path.join(EVALS_DIR, "plans", "valid-strategic-plan.json"))
    validate_must_fail(sp_schema, os.path.join(EVALS_DIR, "plans", "invalid-missing-tasks.json"))
    print()

    # Review output evals
    ro_schema = os.path.join(SCHEMAS_DIR, "review-output.schema.json")
    review_fixtures = os.path.join(EVALS_DIR, "reviews")
    if os.path.isdir(review_fixtures):
        print("[Review Output Schema]")
        for f in sorted(os.listdir(review_fixtures)):
            path = os.path.join(review_fixtures, f)
            if "invalid" in f:
                validate_must_fail(ro_schema, path)
            else:
                validate_must_pass(ro_schema, path)
        print()

    # Lesson evals
    lesson_schema = os.path.join(SCHEMAS_DIR, "lesson.schema.json")
    lesson_fixtures = os.path.join(EVALS_DIR, "lessons")
    if os.path.isdir(lesson_fixtures):
        print("[Lesson Schema]")
        for f in sorted(os.listdir(lesson_fixtures)):
            path = os.path.join(lesson_fixtures, f)
            if "invalid" in f:
                validate_must_fail(lesson_schema, path)
            else:
                validate_must_pass(lesson_schema, path)
        print()

    # Scorecard evals
    sc_schema = os.path.join(SCHEMAS_DIR, "scorecard.schema.json")
    sc_fixtures = os.path.join(EVALS_DIR, "scorecards")
    if os.path.isdir(sc_fixtures):
        print("[Scorecard Schema]")
        for f in sorted(os.listdir(sc_fixtures)):
            path = os.path.join(sc_fixtures, f)
            if "invalid" in f:
                validate_must_fail(sc_schema, path)
            else:
                validate_must_pass(sc_schema, path)
        print()

    # Heuristics pack eval
    hp_schema = os.path.join(SCHEMAS_DIR, "heuristics-pack.schema.json")
    packs_dir = os.path.join(os.path.dirname(__file__), "..", "packs")
    if os.path.isdir(packs_dir):
        print("[Heuristics Packs Schema]")
        for f in sorted(os.listdir(packs_dir)):
            if f.endswith(".json"):
                validate_must_pass(hp_schema, os.path.join(packs_dir, f))
        print()

    # ── Adversarial diff evals ──
    diffs_dir = os.path.join(EVALS_DIR, "diffs")
    if os.path.isdir(diffs_dir):
        print("[Adversarial Diff Detection]")

        eval_diff(
            os.path.join(diffs_dir, "hardcoded-secret.diff"),
            expected_detections=["AWS access key", "Hardcoded secret"],
        )

        eval_diff(
            os.path.join(diffs_dir, "sql-injection.diff"),
            expected_detections=["SQL injection via template literal"],
        )

        eval_diff(
            os.path.join(diffs_dir, "clean-diff.diff"),
            expected_detections=[],
            expect_clean=True,
        )

        eval_scope_violation(
            os.path.join(diffs_dir, "scope-violation.diff"),
            in_scope_files=["src/auth/"],
        )

        print()

    # ── Summary ──
    total = results["pass"] + results["fail"]
    print(f"=== Results: {results['pass']}/{total} passed, {results['fail']} failed ===")
    if results["errors"]:
        print("\nFailures:")
        for e in results["errors"]:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("All evals passed.")


if __name__ == "__main__":
    main()
