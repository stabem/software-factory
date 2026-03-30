#!/usr/bin/env bash
set -euo pipefail

# Expects PR body text in env var PR_BODY.
# Optional: PR_TITLE for clearer logs.

body="${PR_BODY:-}"
if [[ -z "$body" ]]; then
  echo "❌ Factory gate: PR_BODY is empty"
  exit 1
fi

fail=0

require_pattern() {
  local pattern="$1"
  local message="$2"
  if ! grep -Eqi "$pattern" <<<"$body"; then
    echo "❌ $message"
    fail=1
  else
    echo "✅ $message"
  fi
}

echo "Running Software Factory policy gate..."
[[ -n "${PR_TITLE:-}" ]] && echo "PR: ${PR_TITLE}"

# Mandatory PR sections.
require_pattern "(^|\n)##[[:space:]]*Root[[:space:]]+cause" "Section: ## Root cause present"
require_pattern "(^|\n)##[[:space:]]*Validation" "Section: ## Validation present"
require_pattern "(^|\n)##[[:space:]]*Rollback" "Section: ## Rollback present"

# Change class contract.
require_pattern "Change[[:space:]]*class[[:space:]]*:[[:space:]]*(hotfix|feature|refactor|risky-infra)" "Valid Change class declared"

# Evidence-first expectation.
require_pattern "(go test|npm test|pytest|cargo test|mvn test|gradle test|build passed|ci passed)" "Contains test/build evidence"

if [[ "$fail" -ne 0 ]]; then
  echo "\n❌ Software Factory gate failed."
  echo "Add missing sections in PR body and rerun."
  exit 1
fi

echo "\n✅ Software Factory gate passed."
