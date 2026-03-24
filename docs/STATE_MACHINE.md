# State Machine

Software Factory should know where a project is in the workflow, what artifacts must exist at that point, and what the next valid moves are.

## States
- `uninitialized`
- `mapped`
- `discussed`
- `planned`
- `executing`
- `verifying`
- `blocked`
- `shipped`
- `archived`

## State Definitions

### uninitialized
No structured workflow artifacts exist yet.

### mapped
The repo or project has been bootstrapped or codebase-mapped enough to start work safely.

### discussed
Scope boundaries, locked decisions, or assumptions were reviewed and frozen for the current phase.

### planned
At least one executable plan exists with requirements, ownership, dependencies, evidence, and rollback.

### executing
A plan is actively being implemented.

### verifying
Execution finished and proof is being gathered or reviewed.

### blocked
Progress cannot continue without a decision, environment fix, review result, or human action.

### shipped
The change passed verification, PR/review flow, and is merged/deployed as required.

### archived
The work is complete and no longer active.

## Valid Transitions
- `uninitialized -> mapped`
- `mapped -> discussed`
- `discussed -> planned`
- `planned -> executing`
- `executing -> verifying`
- `verifying -> planned` (repair loop)
- `verifying -> shipped`
- `blocked -> planned`
- `blocked -> executing`
- `blocked -> verifying`
- `shipped -> archived`

## Artifact Requirements Per State

| State | Required Artifacts |
|------|---------------------|
| uninitialized | none |
| mapped | AGENTS.md, tasks/, optionally CODEBASE_MAP.md |
| discussed | CONTEXT.md or equivalent scoped intake artifact |
| planned | PLAN.md, STATE.md |
| executing | PLAN.md, STATE.md, active branch/task ownership |
| verifying | SUMMARY.md, VALIDATION.md, STATE.md |
| blocked | STATE.md with blocker reason and next valid actions |
| shipped | verification evidence, PR/review evidence, STATE.md |
| archived | summary and final state captured |

## Resume Rules
When resuming work:
1. read `STATE.md` first
2. confirm current state is still accurate
3. confirm active phase and plan
4. confirm blockers and pending human checks
5. only resume through a valid transition

## Blocked State Rules
Use `blocked` when progress depends on:
- product or technical decision
- broken environment or missing secret/access
- pending verification evidence
- pending review or policy gate

Blocked state must include:
- blocker reason
- owner of unblock step
- next valid actions
- what must not proceed yet

## Anti-Patterns
- skipping directly from planning to shipped
- running execution with no active plan
- marking work complete before verification or PR gate
- using blocked as a vague parking lot with no next action
