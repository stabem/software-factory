# State Machine

Software Factory should know where a project is in the workflow, which artifacts must exist, and what transitions are valid.

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

### `uninitialized`
No factory artifacts have been created yet.

### `mapped`
The repo has been bootstrapped and, for brownfield work, initial structure/conventions are known.

### `discussed`
Scope boundaries, assumptions, and locked decisions for the current work are clarified.

### `planned`
A plan exists with scope, validation, rollback, and execution boundaries.

### `executing`
Implementation is active.

### `verifying`
Execution finished and the change is being verified against expected outcomes.

### `blocked`
The workflow cannot continue without a decision, access, environment fix, or review outcome.

### `shipped`
The work passed validation and the PR/review/deploy path is complete.

### `archived`
The work is complete and no longer active.

## Valid Transitions
- `uninitialized -> mapped`
- `mapped -> discussed`
- `discussed -> planned`
- `planned -> executing`
- `executing -> verifying`
- `verifying -> planned` (repair loop)
- `verifying -> shipped`
- `blocked -> discussed`
- `blocked -> planned`
- `blocked -> executing`
- `blocked -> verifying`
- `shipped -> archived`

## Artifact Requirements Per State

| State | Required artifacts |
|------|---------------------|
| `uninitialized` | none |
| `mapped` | `AGENTS.md`, task files, bootstrap artifacts |
| `discussed` | approved scope/decisions for current work |
| `planned` | `tasks/plan.md` or equivalent approved plan |
| `executing` | plan + task packet(s) + validation commands |
| `verifying` | execution evidence + validation evidence |
| `blocked` | blocker reason + next valid action |
| `shipped` | PR/review/deploy evidence |
| `archived` | summary / final record |

## Resume Rules
When resuming work:
1. read the active plan first
2. identify current state
3. confirm blockers and pending human checks
4. resume only through a valid transition

## Blocked Rules
A blocked state must record:
- blocker reason
- what is waiting on whom
- next valid action
- what must not proceed yet

## Anti-Patterns
- jumping from planning to shipped
- implementing with no approved plan
- marking shipped before verification or PR gate
- using blocked as a vague parking lot with no next action
