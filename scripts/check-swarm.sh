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

REQUIRE_PR_DEFAULT="$(echo "$UPDATED_JSON" | jq -r '.defaults.requirePr // true')"
REQUIRE_MERGED_DEFAULT="$(echo "$UPDATED_JSON" | jq -r '.defaults.requireMerged // false')"
REQUIRE_DEPLOY_DEFAULT="$(echo "$UPDATED_JSON" | jq -r '.defaults.requireDeployValidation // false')"

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

  REQUIRE_PR="$(echo "$TASK_JSON" | jq -r '.requirePr // empty')"
  REQUIRE_MERGED="$(echo "$TASK_JSON" | jq -r '.requireMerged // empty')"
  REQUIRE_DEPLOY="$(echo "$TASK_JSON" | jq -r '.requireDeployValidation // empty')"
  [[ -z "$REQUIRE_PR" || "$REQUIRE_PR" == "null" ]] && REQUIRE_PR="$REQUIRE_PR_DEFAULT"
  [[ -z "$REQUIRE_MERGED" || "$REQUIRE_MERGED" == "null" ]] && REQUIRE_MERGED="$REQUIRE_MERGED_DEFAULT"
  [[ -z "$REQUIRE_DEPLOY" || "$REQUIRE_DEPLOY" == "null" ]] && REQUIRE_DEPLOY="$REQUIRE_DEPLOY_DEFAULT"

  [[ "$STATUS" == "done" || "$STATUS" == "blocked" ]] && continue

  # 0) Definition of Ready sanity check (if present)
  if echo "$TASK_JSON" | jq -e '.ready? | type == "object"' >/dev/null; then
    NOT_READY_KEYS="$(echo "$TASK_JSON" | jq -r '.ready | to_entries[] | select(.value == false) | .key' | paste -sd, -)"
    if [[ -n "$NOT_READY_KEYS" ]]; then
      ALERTS+=("WARN $TASK_ID: not ready (missing: $NOT_READY_KEYS)")
    fi
  fi

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

  # 2) PR/check status (if branch exists and gh is available)
  if [[ -n "$BRANCH" ]] && command -v gh >/dev/null 2>&1; then
    PR_NUMBER="$(gh pr list --state all --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)"
    if [[ -n "$PR_NUMBER" && "$PR_NUMBER" != "null" ]]; then
      UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --argjson n "$PR_NUMBER" '(.tasks[] | select(.id==$id) | .pr.number) = $n')"

      PR_META="$(gh pr view "$PR_NUMBER" --json state,mergedAt,url 2>/dev/null || echo '{}')"
      PR_STATE="$(echo "$PR_META" | jq -r '.state // "UNKNOWN"')"
      PR_URL="$(echo "$PR_META" | jq -r '.url // empty')"
      PR_MERGED_AT="$(echo "$PR_META" | jq -r '.mergedAt // empty')"

      UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --arg st "$PR_STATE" --arg url "$PR_URL" --arg ma "$PR_MERGED_AT" '
        (.tasks[] | select(.id==$id) | .pr.state) = $st |
        (.tasks[] | select(.id==$id) | .pr.url) = (if $url=="" then .pr.url else $url end) |
        (.tasks[] | select(.id==$id) | .pr.mergedAt) = (if $ma=="" then .pr.mergedAt else $ma end)
      ')"

      CHECKS_JSON="$(gh pr checks "$PR_NUMBER" --json name,state 2>/dev/null || echo '[]')"
      REVIEW_STATE="pending"
      CI_STATE="pending"

      # simple mapping by check names containing substrings
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

      UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" --arg rv "$REVIEW_STATE" --arg ci "$CI_STATE" '
        (.tasks[] | select(.id==$id) | .checks.review) = $rv |
        (.tasks[] | select(.id==$id) | .checks.ci) = $ci
      ')"

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
  PRS="$(echo "$TASK_NOW" | jq -r '.pr.state // empty')"
  DEPLOY_VALIDATED="$(echo "$TASK_NOW" | jq -r '.deploy.validated // false')"

  CHECKS_OK=false
  if [[ "$RV" == "passed" && "$CI" == "passed" ]]; then
    CHECKS_OK=true
  fi

  PR_OK=true
  if [[ "$REQUIRE_PR" == "true" ]]; then
    [[ -n "$PRN" && "$PRN" != "null" ]] || PR_OK=false
  fi

  MERGE_OK=true
  if [[ "$REQUIRE_MERGED" == "true" ]]; then
    [[ "$PRS" == "MERGED" ]] || MERGE_OK=false
  fi

  DEPLOY_OK=true
  if [[ "$REQUIRE_DEPLOY" == "true" ]]; then
    [[ "$DEPLOY_VALIDATED" == "true" ]] || DEPLOY_OK=false
  fi

  if [[ "$CHECKS_OK" == "true" && "$PR_OK" == "true" && "$MERGE_OK" == "true" && "$DEPLOY_OK" == "true" ]]; then
    UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg id "$TASK_ID" '(.tasks[] | select(.id==$id) | .status) = "done"')"
    ALERTS+=("OK $TASK_ID: marked done (checks green, required gates satisfied)")
  else
    if [[ "$CHECKS_OK" == "true" && "$PR_OK" == "true" && "$MERGE_OK" == "false" ]]; then
      ALERTS+=("INFO $TASK_ID: waiting merge gate before done")
    fi
    if [[ "$CHECKS_OK" == "true" && "$PR_OK" == "true" && "$MERGE_OK" == "true" && "$DEPLOY_OK" == "false" ]]; then
      ALERTS+=("INFO $TASK_ID: waiting deploy validation gate before done")
    fi
  fi

done

UPDATED_JSON="$(echo "$UPDATED_JSON" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.updatedAt = $ts')"
echo "$UPDATED_JSON" > "$REGISTRY_PATH"

if (( ${#ALERTS[@]} == 0 )); then
  echo "SWARM_OK"
else
  printf '%s\n' "${ALERTS[@]}"
fi
