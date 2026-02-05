# 🏭 Software Factory

Multi-agent development system. 6 specialized AI agents work together to build software.

## 🎯 Goals

**The primary objectives of this system are:**

1. **Token Efficiency** - Reduce context bloat by having specialized agents with focused instructions
2. **Better Context** - Each agent maintains relevant context, avoiding information overload
3. **Documented History** - Track what was changed, why, and lessons learned for future LLM sessions

> **Key Insight:** When an LLM session ends, context is lost. The `.agent-comms/` directory serves as persistent memory, enabling future sessions to understand past decisions and avoid repeating mistakes.

## How It Works

**One task flows through specialized agents in sequence:**

```
Human: "Add user authentication"
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR (you, the main AI)                            │
│  - Receives task from human                                 │
│  - Delegates to specialized agents                          │
│  - Monitors progress in PLAN.md                             │
│  - Resolves conflicts                                       │
│  - Documents validated changes in HISTORY.md                │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  1. ARCHITECT 🏗️                                            │
│  Input:  Feature request                                    │
│  Does:   Designs solution, breaks into tasks                │
│  Output: Design doc + task list in PLAN.md                  │
│  Rules:  NO CODE - only design                              │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  2. BUILDER 🔨                                              │
│  Input:  Task list from Architect                           │
│  Does:   Writes production code                             │
│  Output: Commits on agent/builder branch                    │
│  Rules:  Follow design exactly, atomic commits              │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  3. VALIDATION (parallel)                                   │
│                                                             │
│  TESTER 🧪         REVIEWER 🔍        SECURITY 🛡️           │
│  - Unit tests      - Code review      - Vuln scan          │
│  - Integration     - Best practices   - OWASP Top 10       │
│  - Coverage 80%+   - Find bugs        - Dependency audit   │
│                                                             │
│  All three update PLAN.md with findings                     │
│  If issues found → back to BUILDER                          │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  4. DOCWRITER 📝                                            │
│  Input:  Approved code                                      │
│  Does:   Updates CLAUDE.md, README, changelog               │
│  Output: Documentation for the changes                      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  5. MERGE & DOCUMENT                                        │
│  - Orchestrator merges agent/builder → main                 │
│  - Updates HISTORY.md with validated changes                │
│  - Records lessons learned for future context               │
│  Task complete ✅                                           │
└─────────────────────────────────────────────────────────────┘
```

## The 6 Agents

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| 🏗️ **Architect** | Design systems | Feature request | Design + tasks in PLAN.md |
| 🔨 **Builder** | Write code | Tasks from PLAN.md | Commits on branch |
| 🧪 **Tester** | Write tests | Code from Builder | Test results in PLAN.md |
| 🔍 **Reviewer** | Code review | Code from Builder | Review in PLAN.md |
| 🛡️ **Security** | Security audit | Code from Builder | Audit in PLAN.md |
| 📝 **DocWriter** | Documentation | Approved code | Updated docs |

## Communication: PLAN.md

All agents read and write to `.agent-comms/PLAN.md`. This is the single source of truth.

```markdown
# Project Plan

## Active Tasks
| ID | Agent | Status | Description |
|----|-------|--------|-------------|
| T1 | architect | ✅ Done | Design auth system |
| T2 | builder | 🔄 WIP | Implement JWT auth |
| T3 | tester | ⏳ Pending | Write auth tests |

## Messages
### Builder → Architect (10:25)
Should I use JWT or sessions?

### Architect → Builder (10:28)
JWT. See design section 3.2.
```

**Status icons:**
- ✅ Done
- 🔄 WIP (working)
- ⏳ Pending (waiting)
- ❌ Blocked
- 🔴 Failed

## File Structure

```
your-project/
├── .agent-comms/
│   ├── PLAN.md              # Master document - ALL agents use this
│   ├── HISTORY.md           # Validated changes log (for future context)
│   ├── tasks.json           # Structured task queue
│   └── ORCHESTRATION.md     # Detailed workflow guide
├── agents/
│   ├── architect.md         # Instructions for Architect agent
│   ├── builder.md           # Instructions for Builder agent
│   ├── tester.md            # Instructions for Tester agent
│   ├── reviewer.md          # Instructions for Reviewer agent
│   ├── security.md          # Instructions for Security agent
│   └── docwriter.md         # Instructions for DocWriter agent
├── worktrees/               # Git worktrees (created by setup script)
│   ├── architect/           # Architect works here
│   ├── builder/             # Builder works here
│   └── ...
└── scripts/
    ├── setup-worktrees.sh   # Linux/Mac setup
    └── setup-factory.ps1    # Windows setup
```

## Quick Setup

```bash
# 1. In your existing project, pull the template
npx degit stabem/software-factory .factory --force
cp -r .factory/* .
rm -rf .factory

# 2. Create git worktrees for each agent
./scripts/setup-worktrees.sh      # Linux/Mac
.\scripts\setup-factory.ps1       # Windows

# 3. Start using it
# Edit .agent-comms/PLAN.md to add tasks
```

## How to Spawn Agents

### Option 1: Subagents (recommended)

The orchestrator spawns specialized agents that work in the **project directory**:

```
sessions_spawn(
  task="You are the Tester agent. Read agents/tester.md for instructions. 
        Test the code in internal/auth/. Update .agent-comms/PLAN.md with results.",
  label="tester-auth"
)
```

> **Important:** Agents always work relative to the project root. Use relative paths (e.g., `./internal/`, `./.agent-comms/`) not absolute paths.

### Option 2: Direct prompt
```
Read agents/builder.md for your instructions.
Your task: Implement T2 from .agent-comms/PLAN.md
Work in the project root directory.
Update PLAN.md when done.
```

### Option 3: Separate terminals
```bash
# Terminal 1 - Builder (in project root)
cd /path/to/your-project && claude

# Terminal 2 - Tester (in project root)
cd /path/to/your-project && claude
```

## Example Flow

**Human says:** "Add rate limiting to the API"

**Orchestrator:**
1. Updates PLAN.md: `| T1 | architect | 🔄 WIP | Design rate limiting |`
2. Spawns Architect agent
3. Architect writes design in PLAN.md, creates tasks T2-T5
4. Orchestrator spawns Builder for T2
5. Builder implements, commits, updates PLAN.md
6. Orchestrator spawns Tester + Reviewer + Security (parallel)
7. All three report in PLAN.md
8. If issues → back to Builder
9. If approved → Orchestrator spawns DocWriter
10. DocWriter updates docs
11. Orchestrator merges to main
12. **Documents in HISTORY.md:** what changed, why, lessons learned
13. Reports to human: "Done ✅"

## Documenting Validated Changes

**After a feature/fix is validated and merged, the Orchestrator MUST update `.agent-comms/HISTORY.md`:**

```markdown
## 2026-02-05: Rate Limiting Implementation

### What Changed
- Added rate limiting middleware in `internal/middleware/ratelimit.go`
- Configured 100 req/min per IP
- Added Redis backend for distributed counting

### Why
- API was being hammered by scrapers
- Previous in-memory solution didn't work across pods

### Lessons Learned
- Redis INCR with EXPIRE is atomic and perfect for this
- Don't forget to exclude health check endpoints

### Files Modified
- internal/middleware/ratelimit.go (new)
- internal/middleware/middleware.go
- configs/config.yaml

### Commits
- abc1234: feat: add rate limiting middleware
- def5678: fix: exclude health endpoints from rate limit
```

This history helps future LLM sessions understand:
- **What** was done (don't reinvent the wheel)
- **Why** it was done (understand the reasoning)
- **Lessons learned** (avoid repeating mistakes)

## Key Rules

1. **PLAN.md is the source of truth** - Every agent reads/writes here
2. **HISTORY.md is persistent memory** - Document validated changes for future context
3. **Architect never codes** - Design only
4. **Builder follows design exactly** - No architecture changes without Architect
5. **Security can veto** - Critical findings block merge
6. **Atomic commits** - One logical change per commit
7. **Read before modify** - Always read CLAUDE.md of a package before changing it
8. **Use relative paths** - Never hardcode absolute paths like `/home/user/project`

## License

MIT
