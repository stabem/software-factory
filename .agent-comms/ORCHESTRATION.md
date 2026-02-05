# 🏭 Software Factory - Orchestration Guide

## ⚠️ File Location

**These files must be INSIDE each project directory:**

```
✅ /opt/bybit-agents/.agent-comms/PLAN.md
✅ /opt/content-api/.agent-comms/PLAN.md
❌ /home/user/clawd/.agent-comms/PLAN.md   ← NOT in workspace root
```

Each project has its own `.agent-comms/` folder with its own PLAN.md and HISTORY.md.

---

## 🎯 Primary Goals

1. **Token Efficiency** - Specialized agents = smaller, focused context
2. **Better Context** - Each agent knows only what it needs
3. **Persistent Memory** - HISTORY.md captures lessons for future sessions

> **Remember:** LLM context is lost between sessions. The `.agent-comms/` directory IS your persistent memory.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (Clawd)                      │
│         Distributes tasks, monitors, resolves conflicts      │
│         Documents validated changes in HISTORY.md            │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   ARCHITECT   │   │    BUILDER    │   │   REVIEWER    │
│ Plans/Design  │   │ Implements    │   │ Code Review   │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│    TESTER     │   │   SECURITY    │   │   DOCWRITER   │
│ Unit/E2E tests│   │ Vuln/Audit    │   │ CLAUDE.md/Docs│
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## Workflow

### Phase 1: Planning
1. Human describes feature/bug
2. Orchestrator → Architect
3. Architect creates design in PLAN.md
4. Orchestrator reviews and approves

### Phase 2: Implementation
1. Orchestrator → Builder (with tasks from PLAN.md)
2. Builder implements in the project directory
3. Builder commits + pushes to branch
4. Orchestrator notifies next phase

### Phase 3: Validation (parallel)
1. Orchestrator → Tester + Reviewer + Security
2. Each agent works in the project directory
3. Results go to PLAN.md
4. If issues: back to Builder

### Phase 4: Documentation
1. Orchestrator → DocWriter
2. Updates CLAUDE.md of affected packages
3. Updates README, changelog

### Phase 5: Merge & Document ⭐
1. Orchestrator merges to main
2. Resolves conflicts if any
3. **Updates HISTORY.md** with:
   - What changed and why
   - Lessons learned
   - Files modified
   - Commit references
4. Final report to human

---

## Communication

All agents read and write to `.agent-comms/PLAN.md`

### Task Status Updates
```markdown
| T1 | builder | 🔄 WIP | P0 | Implement feature X | T0 |
```

### Messages Between Agents
```markdown
### Builder → Architect (10:25)
Question: JWT or session-based?

### Architect → Builder (10:28)
JWT. Stateless is better for our case.
```

---

## Spawning Agents

### Via sessions_spawn
```
sessions_spawn(
  task="You are the Tester agent. Read agents/tester.md for your instructions.
        Your project root is the current directory.
        Test the code in ./internal/auth/
        Update ./.agent-comms/PLAN.md with results.",
  label="tester-task-001"
)
```

> **⚠️ Always use relative paths!** Never hardcode absolute paths like `F:\project\` or `/home/user/project/`. Use `./` for project-relative paths.

### Via Direct Terminal
```bash
# In project root
cd /path/to/your-project
claude --workspace .
```

---

## After Validation: Document in HISTORY.md

**This is critical for future context!**

When a change is validated and merged:

```markdown
## 2026-02-05: Fixed Authentication Bug

### What Changed
- Fixed JWT expiration check in `./internal/auth/jwt.go`
- Added refresh token rotation

### Why
- Users were getting logged out randomly
- Root cause: timezone mismatch in expiration check

### Lessons Learned
- Always use UTC for token timestamps
- Add integration tests for auth flows across timezones
- The `time.Now()` vs `time.Now().UTC()` gotcha

### Files Modified
- ./internal/auth/jwt.go (modified)
- ./internal/auth/jwt_test.go (modified)

### Commits
- a1b2c3d: fix: use UTC for JWT expiration check
- e4f5g6h: test: add timezone edge case tests
```

---

## Best Practices

1. **Atomic commits** - One logical change per commit
2. **Update PLAN.md** - Always update status after completing work
3. **Read CLAUDE.md** - Each package has context, read before modifying
4. **No architecture changes without Architect** - Builder follows design
5. **Security has veto** - Critical findings block merge
6. **Document everything** - HISTORY.md is your persistent memory
7. **Use relative paths** - `./internal/` not `/absolute/path/internal/`

---

## File Reference

| File | Purpose | Updated By |
|------|---------|------------|
| `.agent-comms/PLAN.md` | Active tasks, messages | All agents |
| `.agent-comms/HISTORY.md` | Validated changes log | Orchestrator |
| `.agent-comms/tasks.json` | Structured task queue | Architect, Orchestrator |
| `agents/*.md` | Agent instructions | Maintainer |
