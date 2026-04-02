# Agent Contracts — Software Factory v2.0

> Each agent reads its contract at session start and operates within defined boundaries.
> Agents do NOT communicate with each other. They read shared files (STATE.md, PLAN.md) for coordination.

## Agent Catalog

| Agent | Primary Phase | Role | Contract |
|-------|--------------|------|----------|
| Orchestrator | All | Receives request, routes to phases, delegates, integrates | [orchestrator.md](orchestrator.md) |
| Investigator | INVESTIGATE | Queries DB, reads logs, traces code, produces RESEARCH.md | [investigator.md](investigator.md) |
| Planner | DISCUSS + PLAN | Facilitates discussion, captures decisions, produces PLAN.md | [planner.md](planner.md) |
| Implementer | EXECUTE | Executes task packets within file boundaries, produces evidence | [implementer.md](implementer.md) |
| Debugger | EXECUTE | Auto-repairs mechanical failures (max 2 attempts) | [debugger.md](debugger.md) |
| QA Guardian | VERIFY | Independent test execution, coverage, residual risk | [qa-guardian.md](qa-guardian.md) |
| UAT Verifier | VERIFY | User acceptance testing against requirements | [uat-verifier.md](uat-verifier.md) |
| Reviewer | PR GATE | PR review: correctness, security, scalability | [reviewer.md](reviewer.md) |

## Routing Rules

### By Change Class

| Change Class | DISCUSS | Agents | Waves |
|-------------|---------|--------|-------|
| hotfix | skip | 1 implementer | 1 wave |
| feature | required | 1-3 mixed | multi-wave |
| refactor | optional | 1-2 implementers | multi-wave |
| risky-infra | required | 2-3 mixed | multi-wave + staged |

### By Task Complexity

| Complexity | Model Tier | Agent Count |
|-----------|-----------|-------------|
| Architecture / high-risk | Strongest reasoning model | 1 (focused) |
| Mechanical refactor | Fast coding model | 1-2 (parallel) |
| Research / exploration | Cheap parallel workers | 2-3 + orchestrator synthesis |

## Issue-First Rule

Every implementation task starts with a GitHub Issue. The orchestrator creates the issue using `.github/ISSUE_TEMPLATE/`, the implementer works against it, and the reviewer validates traceability. See [AGENTS.md](../AGENTS.md#issue-first-development-non-negotiable) for the full workflow.

## Isolation Rules

1. **No agent-to-agent communication.** Agents coordinate through shared files only.
2. **Each agent gets fresh context.** No conversation history inheritance.
3. **File ownership is exclusive.** One agent per file within a wave.
4. **Evidence is mandatory.** No "done" without build/test proof.
5. **Issue-first is mandatory.** No branch without an issue. No PR without an issue link.
