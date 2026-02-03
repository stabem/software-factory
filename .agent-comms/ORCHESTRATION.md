# 🏭 Software Factory - Orchestration Guide

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (Clawd)                      │
│         Distributes tasks, monitors, resolves conflicts      │
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

## Workflow

### Phase 1: Planning
1. Human describes feature/bug
2. Orchestrator → Architect
3. Architect creates design in PLAN.md
4. Orchestrator reviews and approves

### Phase 2: Implementation
1. Orchestrator → Builder (with tasks from PLAN.md)
2. Builder implements in their worktree
3. Builder commits + pushes to branch
4. Orchestrator notifies next phase

### Phase 3: Validation (parallel)
1. Orchestrator → Tester + Reviewer + Security
2. Each agent works in their worktree
3. Results go to PLAN.md
4. If issues: back to Builder

### Phase 4: Documentation
1. Orchestrator → DocWriter
2. Updates CLAUDE.md of affected packages
3. Updates README, changelog

### Phase 5: Merge
1. Orchestrator merges worktrees
2. Resolves conflicts if any
3. Final PR to main

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

## Spawning Agents

### Via sessions_spawn
```
sessions_spawn(
  task="Read agents/tester.md and test the code in internal/...",
  label="tester-task-001"
)
```

### Via Direct Terminal
```bash
cd worktrees/tester
claude --workspace .
```

## Best Practices

1. **Atomic commits** - One logical change per commit
2. **Update PLAN.md** - Always update status after completing work
3. **Read CLAUDE.md** - Each package has context, read before modifying
4. **No architecture changes without Architect** - Builder follows design
5. **Security has veto** - Critical findings block merge
