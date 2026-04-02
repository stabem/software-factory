#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="."
FORCE=""
MODE="standard"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ -z "${2:-}" || "${2:-}" == --* ]] && { echo "Error: --mode requires a value" >&2; exit 1; }
      MODE="$2"
      shift 2
      ;;
    --force)
      FORCE="--force"
      shift
      ;;
    --v2)
      MODE="factory"
      shift
      ;;
    -h|--help)
      echo "Usage: bootstrap-factory.sh [target-dir] [--mode fast|standard|factory] [--v2] [--force]"
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

case "$MODE" in
  fast|standard|factory) ;;
  *) echo "Invalid --mode: $MODE" >&2; exit 1 ;;
esac

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

copy_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" && "$FORCE" != "--force" ]]; then
    echo "↩️  skip (exists): $dst"
    return
  fi

  cp "$src" "$dst"
  echo "✅ copied: $dst"
}

echo "Bootstrapping Software Factory into: $TARGET_DIR (mode: $MODE)"

copy_file "$ROOT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
copy_file "$ROOT_DIR/tasks/todo.md" "$TARGET_DIR/tasks/todo.md"
copy_file "$ROOT_DIR/tasks/lessons.md" "$TARGET_DIR/tasks/lessons.md"
copy_file "$ROOT_DIR/templates/PLAN.md" "$TARGET_DIR/tasks/plan.md"

if [[ "$MODE" != "fast" ]]; then
  copy_file "$ROOT_DIR/templates/CLAUDE.qa.md" "$TARGET_DIR/CLAUDE.md"
  copy_file "$ROOT_DIR/templates/qa-guardian.workflow.yml" "$TARGET_DIR/.github/workflows/qa-guardian.yml"
  copy_file "$ROOT_DIR/templates/factory-policy.workflow.yml" "$TARGET_DIR/.github/workflows/factory-policy.yml"
  copy_file "$ROOT_DIR/scripts/check-factory-gate.sh" "$TARGET_DIR/scripts/check-factory-gate.sh"
  copy_file "$ROOT_DIR/.github/ISSUE_TEMPLATE/implementation_task.yml" "$TARGET_DIR/.github/ISSUE_TEMPLATE/implementation_task.yml"
  copy_file "$ROOT_DIR/.github/ISSUE_TEMPLATE/bug_report.yml" "$TARGET_DIR/.github/ISSUE_TEMPLATE/bug_report.yml"
  copy_file "$ROOT_DIR/.github/ISSUE_TEMPLATE/config.yml" "$TARGET_DIR/.github/ISSUE_TEMPLATE/config.yml"
  copy_file "$ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md" "$TARGET_DIR/.github/PULL_REQUEST_TEMPLATE.md"
fi

if [[ "$MODE" == "factory" ]]; then
  copy_file "$ROOT_DIR/templates/swarm.tasks.example.json" "$TARGET_DIR/.swarm/tasks.json"
  copy_file "$ROOT_DIR/scripts/check-swarm.sh" "$TARGET_DIR/scripts/check-swarm.sh"
  copy_file "$ROOT_DIR/docs/SWARM_RUNBOOK.md" "$TARGET_DIR/docs/SWARM_RUNBOOK.md"
  copy_file "$ROOT_DIR/docs/VERIFICATION_MODEL.md" "$TARGET_DIR/docs/VERIFICATION_MODEL.md"
  copy_file "$ROOT_DIR/docs/STATE_MACHINE.md" "$TARGET_DIR/docs/STATE_MACHINE.md"
fi

chmod +x "$TARGET_DIR/scripts/check-factory-gate.sh" 2>/dev/null || true
chmod +x "$TARGET_DIR/scripts/check-swarm.sh" 2>/dev/null || true

echo ""
echo "🎯 Next steps"
echo "1) Fill commands/placeholders in tasks/plan.md"
if [[ "$MODE" != "fast" ]]; then
  echo "2) Fill commands/placeholders in CLAUDE.md"
  echo "3) Configure required secrets (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)"
  echo "4) Set branch protection to require: Factory Policy Gate + QA/Security guards"
fi
if [[ "$MODE" == "factory" ]]; then
  echo "5) Initialize swarm registry/monitor assets if needed"
fi
