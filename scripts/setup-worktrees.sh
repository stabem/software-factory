#!/bin/bash
# Setup Git Worktrees for Multi-Agent Development
# Usage: ./scripts/setup-worktrees.sh

set -e

AGENTS=("architect" "builder" "tester" "reviewer" "security" "docwriter")

# Verify it's a git repo
if [ ! -d ".git" ]; then
    echo "❌ Not a git repository"
    exit 1
fi

echo "🏭 Setting up Software Factory..."

# Create directories
mkdir -p worktrees
mkdir -p .agent-comms/messages

# Create worktree for each agent
for agent in "${AGENTS[@]}"; do
    if [ -d "worktrees/$agent" ]; then
        echo "⚠️  Worktree exists: worktrees/$agent"
    else
        echo "📁 Creating worktree: $agent"
        git worktree add "worktrees/$agent" -b "agent/$agent" 2>/dev/null || \
        git worktree add "worktrees/$agent" "agent/$agent" 2>/dev/null || \
        git worktree add "worktrees/$agent" -b "agent/$agent"
    fi
done

# Add to .gitignore if not present
if ! grep -q "worktrees/" .gitignore 2>/dev/null; then
    echo "worktrees/" >> .gitignore
    echo "📝 Added worktrees/ to .gitignore"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Worktrees:"
git worktree list
echo ""
echo "Next: Update .agent-comms/PLAN.md with your tasks"
