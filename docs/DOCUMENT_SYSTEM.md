# Document System

Software Factory uses documents as workflow contracts, not as passive notes. Each document exists to reduce ambiguity, narrow context, and create a reliable handoff between stages.

## Core Principle
Documents are part of the operating system of the repo.

A good document:
- has a clear producer
- has clear consumers
- is updated at the right moment
- stays small enough to load directly into an agent
- prevents repeated re-explanation in chat

## Document Roles

### Strategic documents
Longer-lived context that defines what the project is and how it should behave.

### Operational documents
Artifacts that freeze the current work packet and guide execution.

### Execution documents
Artifacts that capture what was actually done.

### Verification documents
Artifacts that define or capture proof.

## Contract Matrix

### `AGENTS.md`
- **Purpose:** repo-level methodology and operating rules
- **Producer:** framework maintainer / repo owner
- **Consumers:** all agents
- **Update trigger:** methodology change
- **Anti-patterns:** project-specific execution logs, stale process rules, duplicate reference sections

### `tasks/todo.md`
- **Purpose:** active checklist for current work
- **Producer:** orchestrator / implementer
- **Consumers:** orchestrator, implementer, reviewer
- **Update trigger:** task progress changes
- **Anti-patterns:** turning it into a journal, keeping completed stale work forever in the active section

### `tasks/lessons.md`
- **Purpose:** durable lessons learned from failures and corrections
- **Producer:** orchestrator / reviewer / implementer
- **Consumers:** future planning and verification
- **Update trigger:** mistakes, surprises, regressions, postmortems
- **Anti-patterns:** vague lessons with no actionable rule, deleting old lessons

### `tasks/plan.md`
- **Purpose:** approved implementation contract for the current change
- **Producer:** planner / orchestrator
- **Consumers:** implementer, reviewer, QA
- **Update trigger:** before execution, or after explicit re-plan
- **Anti-patterns:** implementation logs mixed into plan, missing validation/rollback, fuzzy scope

### `CLAUDE.md`
- **Purpose:** role contract for QA/guard execution
- **Producer:** repo owner / framework bootstrap
- **Consumers:** QA guard or equivalent reviewer agent
- **Update trigger:** QA contract changes, repo validation command changes
- **Anti-patterns:** general methodology dump, duplicated AGENTS content, missing repo-specific commands

### `.swarm/tasks.json`
- **Purpose:** machine-readable swarm task registry
- **Producer:** orchestrator / monitor loop
- **Consumers:** monitor scripts, orchestrator, reviewers
- **Update trigger:** task lifecycle changes
- **Anti-patterns:** using it as freeform notes, marking done before checks/merge/deploy gates are satisfied

### `docs/SWARM_RUNBOOK.md`
- **Purpose:** deterministic operating guide for swarm monitoring
- **Producer:** framework maintainer
- **Consumers:** orchestrator / operators
- **Update trigger:** swarm process changes
- **Anti-patterns:** duplicating script logic in too much detail, stale command examples

### `docs/VERIFICATION_MODEL.md`
- **Purpose:** define how Software Factory proves outcomes instead of just completed activity
- **Producer:** framework maintainer
- **Consumers:** planner, implementer, reviewer, QA
- **Update trigger:** verification model changes
- **Anti-patterns:** vague principles without concrete stack/layers, examples disconnected from actual workflows

### `docs/STATE_MACHINE.md`
- **Purpose:** define valid workflow states and transitions
- **Producer:** framework maintainer
- **Consumers:** orchestrator, reviewer, maintainers
- **Update trigger:** workflow lifecycle changes
- **Anti-patterns:** states with no transition rules, transitions with no artifact requirements

## Lifecycle Rules
- Strategic documents change less often than operational ones.
- Plans must be updated before implementation, not retroactively after code is written.
- Verification documents must describe proof, not just intention.
- Execution documents must record facts, not marketing.

## Compactness Rules
- If a document cannot be read quickly in a single agent pass, it is too big.
- Prefer summaries plus references instead of giant catch-all docs.
- Avoid duplicate sections that drift independently.

## Cross-Document Rules
- `AGENTS.md` defines behavior.
- `tasks/plan.md` defines current implementation scope.
- `tasks/todo.md` tracks active execution.
- `tasks/lessons.md` captures durable learning.
- `docs/VERIFICATION_MODEL.md` defines proof standards.
- `docs/STATE_MACHINE.md` defines workflow transitions.
- `.swarm/tasks.json` tracks machine state for delegated work.

## Anti-Patterns for the System
- using chat history as the primary workflow memory
- creating parallel docs with overlapping purpose
- keeping documents that no stage actually reads
- documenting process without connecting it to scripts/templates/workflows
