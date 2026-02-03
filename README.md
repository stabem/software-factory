# 🏭 Software Factory Template

Multi-agent development structure for OpenClaw projects.

## Quick Setup

```bash
# In your existing project
npx degit stabem/software-factory .factory --force
cp -r .factory/* .
rm -rf .factory

# Or with curl
curl -sL https://github.com/stabem/software-factory/archive/main.tar.gz | tar xz --strip=1
```

## Structure

```
your-project/
├── .agent-comms/           # Agent communication
│   ├── PLAN.md             # Master document
│   ├── tasks.json          # Task queue
│   └── ORCHESTRATION.md    # How to use
├── agents/                 # Agent instructions
│   ├── architect.md        # 🏗️ Design agent
│   ├── builder.md          # 🔨 Implementation agent
│   ├── tester.md           # 🧪 Testing agent
│   ├── reviewer.md         # 🔍 Code review agent
│   ├── security.md         # 🛡️ Security audit agent
│   └── docwriter.md        # 📝 Documentation agent
└── scripts/
    └── setup-worktrees.sh  # Create git worktrees
```

## Usage

### 1. Setup worktrees
```bash
./scripts/setup-worktrees.sh
```

### 2. Assign tasks in PLAN.md
```markdown
| ID | Agent | Status | Description |
|----|-------|--------|-------------|
| T1 | architect | 🔄 WIP | Design new feature |
```

### 3. Spawn agents
Each agent reads their instructions from `agents/{role}.md` and works in their worktree.

## Workflow

```
Human → Orchestrator
         ↓
      Architect (design)
         ↓
      Builder (implement)
         ↓
      Tester + Reviewer + Security (parallel)
         ↓
      DocWriter (document)
         ↓
      Merge → Main
```

## License
MIT
