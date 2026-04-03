# Pipeline Self-Evals

This directory contains test fixtures for validating the pipeline's contracts and detection capabilities. Every change to a template, schema, or workflow must pass these evals.

## Fixture Types

### `plans/` — Plan Output Fixtures
- `valid-strategic-plan.json` — Must pass schema validation
- `valid-tactical-plan.json` — Must pass schema validation
- `invalid-missing-tasks.json` — Must fail: no tasks array
- `invalid-overlapping-scope.json` — Must fail: two tasks share files_in_scope in same wave
- `invalid-no-rollback.json` — Must fail: missing rollback field

### `reviews/` — Review Output Fixtures
- `valid-approve.json` — Must pass schema validation, verdict APPROVE
- `valid-request-changes.json` — Must pass schema validation, verdict REQUEST_CHANGES
- `invalid-no-verdict.json` — Must fail: missing verdict field

### `diffs/` — Adversarial PR Diffs
- `hardcoded-secret.diff` — Must trigger critical finding (secrets detection)
- `scope-violation.diff` — Must trigger scope compliance failure
- `sql-injection.diff` — Must trigger critical finding (injection)
- `eval-with-user-input.diff` — Must trigger critical finding (command injection)
- `tls-verification-disabled.diff` — Must trigger critical finding (crypto)
- `clean-diff.diff` — Must pass review with no critical findings

### `lessons/` — Learning Loop Fixtures
- `valid-lesson.json` — Must pass lesson schema validation
- `lesson-dedup.json` — Two lessons with same pattern — must deduplicate

## Running Evals

See `.github/workflows/pipeline-evals.yml` for the CI workflow.

```bash
# Validate all schemas against fixtures
python3 evals/run_evals.py

# Or manually validate a single fixture
python3 -c "
import json, jsonschema
schema = json.load(open('schemas/strategic-plan.schema.json'))
fixture = json.load(open('evals/plans/valid-strategic-plan.json'))
jsonschema.validate(fixture, schema)
print('PASS')
"
```
