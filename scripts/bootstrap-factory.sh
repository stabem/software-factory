#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-.}"
FORCE="${2:-}"

if [[ "$TARGET_DIR" == "--force" ]]; then
  TARGET_DIR="."
  FORCE="--force"
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || true)"
if [[ -z "$TARGET_DIR" ]]; then
  echo "❌ Target directory not found"
  exit 1
fi

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

echo "Bootstrapping Software Factory into: $TARGET_DIR"

copy_file "$ROOT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
copy_file "$ROOT_DIR/tasks/todo.md" "$TARGET_DIR/tasks/todo.md"
copy_file "$ROOT_DIR/tasks/lessons.md" "$TARGET_DIR/tasks/lessons.md"
copy_file "$ROOT_DIR/templates/PLAN.md" "$TARGET_DIR/tasks/plan.md"
copy_file "$ROOT_DIR/templates/CLAUDE.qa.md" "$TARGET_DIR/CLAUDE.md"
copy_file "$ROOT_DIR/templates/qa-guardian.workflow.yml" "$TARGET_DIR/.github/workflows/qa-guardian.yml"
copy_file "$ROOT_DIR/templates/factory-policy.workflow.yml" "$TARGET_DIR/.github/workflows/factory-policy.yml"
copy_file "$ROOT_DIR/scripts/check-factory-gate.sh" "$TARGET_DIR/scripts/check-factory-gate.sh"

chmod +x "$TARGET_DIR/scripts/check-factory-gate.sh" 2>/dev/null || true

echo ""
echo "🎯 Next steps"
echo "1) Fill commands/placeholders in tasks/plan.md and CLAUDE.md"
echo "2) Configure required secrets (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)"
echo "3) Set branch protection to require: Factory Policy Gate + QA/Security guards"
