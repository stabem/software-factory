#!/usr/bin/env bash
set -euo pipefail

SPEC_PATH="${SDD_SPEC_PATH:-specs/current/spec.md}"

# Local: check workspace diff. CI: check PR/commit range.
if [[ -z "${CI:-}" && -z "${GITHUB_ACTIONS:-}" ]]; then
  CHANGED_FILES="$(
    {
      git diff --name-only HEAD 2>/dev/null || true
      git ls-files --others --exclude-standard 2>/dev/null || true
    } | sed '/^$/d' | sort -u
  )"
else
  BASE_REF="origin/${GITHUB_BASE_REF:-main}"
  CHANGED_FILES="$(git diff --name-only "${BASE_REF}"...HEAD 2>/dev/null || git diff --name-only HEAD~1...HEAD 2>/dev/null || true)"
fi

if [[ -z "${CHANGED_FILES}" ]]; then
  echo "[sdd-gate] No changed files."
  exit 0
fi

NON_DOC_CHANGES="$(echo "${CHANGED_FILES}" | grep -Ev '(^docs/|^specs/|\.md$|^README\.md$|^LICENSE$)' || true)"

if [[ -z "${NON_DOC_CHANGES}" ]]; then
  echo "[sdd-gate] Docs-only change. Gate passed."
  exit 0
fi

if [[ ! -f "${SPEC_PATH}" ]]; then
  echo "[sdd-gate] [FAIL] Missing required file: ${SPEC_PATH}"
  exit 1
fi

for section in '^## Problem' '^## Scope' '^## Acceptance Criteria' '^## Validation' '^## Rollback'; do
  if ! grep -Eq "$section" "${SPEC_PATH}"; then
    echo "[sdd-gate] [FAIL] Missing section matching '$section' in ${SPEC_PATH}"
    exit 1
  fi
done

echo "[sdd-gate] [OK] PASSED"
