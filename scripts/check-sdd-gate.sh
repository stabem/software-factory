#!/usr/bin/env bash
set -euo pipefail

SPEC_PATH="${SDD_SPEC_PATH:-}"
TEMPLATE_PATH="templates/spec.md"

if [[ -z "${SPEC_PATH}" ]]; then
  if [[ -f "specs/current/spec.md" ]]; then
    SPEC_PATH="specs/current/spec.md"
  else
    CANDIDATES=()
    while IFS= read -r file; do
      CANDIDATES+=("${file}")
    done < <(find specs/current -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | sort)

    if [[ ${#CANDIDATES[@]} -eq 1 ]]; then
      SPEC_PATH="${CANDIDATES[0]}"
    elif [[ ${#CANDIDATES[@]} -gt 1 ]]; then
      echo "[sdd-gate] [FAIL] Multiple specs found in specs/current/. Set SDD_SPEC_PATH explicitly."
      exit 1
    fi
  fi
fi

# Local: include staged + unstaged + untracked.
# CI: compare branch against base ref.
if [[ -z "${CI:-}" && -z "${GITHUB_ACTIONS:-}" ]]; then
  CHANGED_FILES="$({
    git diff --name-only --cached 2>/dev/null || true
    git diff --name-only 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null || true
  } | sed '/^$/d' | sort -u)"
else
  BASE_REF="origin/${GITHUB_BASE_REF:-main}"
  CHANGED_FILES="$(git diff --name-only "${BASE_REF}"...HEAD 2>/dev/null || git diff --name-only HEAD~1...HEAD 2>/dev/null || true)"
fi

if [[ -z "${CHANGED_FILES}" ]]; then
  echo "[sdd-gate] No changed files."
  exit 0
fi

NON_DOC_CHANGES="$(echo "${CHANGED_FILES}" | grep -Ev '(^docs/|^specs/|\.md$|^LICENSE$)' || true)"

if [[ -z "${NON_DOC_CHANGES}" ]]; then
  echo "[sdd-gate] Docs-only change. Gate passed."
  exit 0
fi

if [[ -z "${SPEC_PATH}" || ! -f "${SPEC_PATH}" ]]; then
  echo "[sdd-gate] [FAIL] Missing required spec file."
  echo "[sdd-gate] Hint: mkdir -p specs/current && cp templates/spec.md specs/current/<task>.md"
  exit 1
fi

TMP_SPEC="$(mktemp)"
cleanup() { rm -f "${TMP_SPEC}"; }
trap cleanup EXIT
tr -d '\r' < "${SPEC_PATH}" > "${TMP_SPEC}"
SPEC_CHECK_PATH="${TMP_SPEC}"

for section in '^## Problem$' '^## Scope$' '^## Acceptance Criteria$' '^## Validation$' '^## Rollback$'; do
  if ! grep -Eq "$section" "${SPEC_CHECK_PATH}"; then
    echo "[sdd-gate] [FAIL] Missing section matching '$section' in ${SPEC_PATH}"
    exit 1
  fi
done

section_has_real_content() {
  local heading="$1"
  awk -v h="$heading" '
    BEGIN { in_section = 0; has = 0 }
    {
      line_raw = $0
      sub(/\r$/, "", line_raw)
    }
    line_raw ~ /^## / {
      if (in_section) { exit has ? 0 : 1 }
      in_section = (line_raw == h)
      next
    }
    in_section {
      line = line_raw
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^```/) next
      if (line ~ /^#/) next
      has = 1
    }
    END {
      if (!in_section) exit 1
      exit has ? 0 : 1
    }
  ' "${SPEC_CHECK_PATH}"
}

for heading in '## Problem' '## Scope' '## Acceptance Criteria' '## Validation' '## Rollback'; do
  if ! section_has_real_content "$heading"; then
    echo "[sdd-gate] [FAIL] Section '$heading' has no meaningful content in ${SPEC_PATH}"
    exit 1
  fi
done

if [[ -f "${TEMPLATE_PATH}" ]] && diff -q <(tr -d '\r' < "${SPEC_PATH}") <(tr -d '\r' < "${TEMPLATE_PATH}") >/dev/null; then
  echo "[sdd-gate] [FAIL] ${SPEC_PATH} is identical to template. Fill it with task-specific content."
  exit 1
fi

if grep -Eq 'YYYYMMDD-<slug>|What is broken or needed\?|build / test / smoke commands|exact rollback command' "${SPEC_CHECK_PATH}"; then
  echo "[sdd-gate] [FAIL] ${SPEC_PATH} still has template placeholders."
  exit 1
fi

echo "[sdd-gate] [OK] PASSED"
