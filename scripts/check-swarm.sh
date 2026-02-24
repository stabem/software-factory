#!/usr/bin/env bash
set -euo pipefail

REGISTRY_PATH="${1:-.swarm/tasks.json}"
MAX_RETRIES_DEFAULT="${MAX_RETRIES_DEFAULT:-3}"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required" >&2
  exit 2
fi

if [[ ! -f "$REGISTRY_PATH" ]]; then
  echo "ERROR: registry not found at $REGISTRY_PATH" >&2
  exit 2
fi

ALERTS=()
UPDATED_JSON="$(cat "$REGISTRY_PATH")"

# Iterate task IDs once to keep updates safe
mapfile -t TASK_IDS < <(echo "$UPDATED_JSON" | jq -r '.tasks[].id')

for TASK_ID in "${TASK_IDS[@]}"; do
  TASK_JSON="$(echo "$UPDATED_JSON" | jq -c --arg id "$TASK_ID" '.tasks[] | select(.id==$id)')"
  STATUS="$(echo "$TASK_JSON" | jq -r '.status')"
  BRANCH="$(echo "$TASK_JSON" | jq -r '.branch // empty')"
  SESSION_TYPE="$(echo "$TASK_JSON" | jq -r '.session.type // empty')"
  SESSION_NAME="$(echo "$TASK_JSON" | jq -r '.session.name // empty')"
  RETRIES="$(echo "$TASK_JSON" | jq -r '.retries // 0')"
  MAX_RETRIES="$(echo "$TASK_JSON" | jq -r '.maxRetries // empty')"
  [[ -z "$MAX_RETRIES" || "$MAX_RETRIES" == "null" ]] && MAX_RETRIES="$MAX_RETRIES_DEFAULT"

  [[ "$STATUS" == "done" || "$STATUS" == "blocked" ]] && continue

  # 1) Liveness check (tmux only in template)
  if [[ "$SESSION_TYPE" == "tmux" && -n "$SESSION_NAME" ]]; then
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      if (( RETRIES < MAX_RETRIES )); then
        RETRIES=$((RETRIES+1))
        ALERTS+=("WARN $TASK_ID: session '$SESSION_NAME' down (retry $RETRIES/$MAX_RETRIES)")
        UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --argjson r "$RETRIES" '(.tasks[] | select(.id==$id) | .retries) = $r')"
      else
        ALERTS+=("CRITICAL $TASK_ID: session '$SESSION_NAME' down and retry budget exhausted")
        UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" '(.tasks[] | select(.id==$id) | .status) = "blocked"')"
      fi
    fi
  fi

  # 2) PR existence and check status (if branch exists)
  if [[ -n "$BRANCH" ]] && command -v gh >/dev/null 2>&1; then
    PR_NUMBER="$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)"
    if [[ -n "$PR_NUMBER" && "$PR_NUMBER" != "null" ]]; then
      UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --argjson n "$PR_NUMBER" '(.tasks[] | select(.id==$id) | .pr.number) = $n')"

      CHECKS_JSON="$(gh pr checks "$PR_NUMBER" --json name,state 2>/dev/null || echo '[]')"
      REVIEW_STATE="pending"
      CI_STATE="pending"

      # very simple mapping by check names containing substrings
      if echo "$CHECKS_JSON" | jq -e '.[] | select((.name|ascii_downcase|contains("review")) and .state=="SUCCESS")' >/dev/null; then
        REVIEW_STATE="passed"
      elif echo "$CHECKS_JSON" | jq -e '.[] | select((.name|ascii_downcase|contains("review")) and .state=="FAILURE")' >/dev/null; then
        REVIEW_STATE="failed"
      fi

      if echo "$CHECKS_JSON" | jq -e '.[] | select((.name|ascii_downcase|contains("ci") or .name|ascii_downcase|contains("test")) and .state=="SUCCESS")' >/dev/null; then
        CI_STATE="passed"
      elif echo "$CHECKS_JSON" | jq -e '.[] | select((.name|ascii_downcase|contains("ci") or .name|ascii_downcase|contains("test")) and .state=="FAILURE")' >/dev/null; then
        CI_STATE="failed"
      fi

      UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --arg rv "$REVIEW_STATE" --arg ci "$CI_STATE" '(.tasks[] | select(.id==$id) | .checks.review) = $rv | (.tasks[] | select(.id==$id) | .checks.ci) = $ci')"

      if [[ "$REVIEW_STATE" == "failed" || "$CI_STATE" == "failed" ]]; then
        ALERTS+=("WARN $TASK_ID: PR #$PR_NUMBER has failing checks (review=$REVIEW_STATE ci=$CI_STATE)")
      fi
    else
      ALERTS+=("INFO $TASK_ID: no PR found yet for branch '$BRANCH'")
    fi
  fi

  # 3) Done transition helper
  TASK_NOW="$(echo "$UPDATED_JSON" | jq -c --arg id "$TASK_ID" '.tasks[] | select(.id==$id)')"
  RV="$(echo "$TASK_NOW" | jq -r '.checks.review // "pending"')"
  CI="$(echo "$TASK_NOW" | jq -r '.checks.ci // "pending"')"
  PRN="$(echo "$TASK_NOW" | jq -r '.pr.number // empty')"

  if [[ -n "$PRN" && "$RV" == "passed" && "$CI" == "passed" ]]; then
    UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" '(.tasks[] | select(.id==$id) | .status) = "done"')"
    ALERTS+=("OK $TASK_ID: marked done (PR #$PRN checks green)")
  fi

done

UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.updatedAt = $ts')"
echo "$UPDATED_JSON" > "$REGISTRY_PATH"

if (( ${#ALERTS[@]} == 0 )); then
  echo "SWARM_OK"
else
  printf '%s\n' "${ALERTS[@]}"
fi
