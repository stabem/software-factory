# Artifact Contracts

Software Factory runs on artifacts, not loose chat memory. Each artifact exists to reduce ambiguity, narrow context, and create a clear handoff between stages.

## Core Principles
- artifacts are contracts, not notes
- every artifact has a producer and consumers
- every artifact has a valid update window
- artifacts must stay compact and stage-specific
- artifacts should reduce context, not accumulate noise

## Artifact Categories

### Strategic Artifacts
Longer-lived context that defines the project and durable decisions.
- `PROJECT.md`
- `DECISIONS.md`

### Operational Artifacts
Artifacts that freeze the current work packet.
- `CONTEXT.md`
- `RESEARCH.md`
- `CODEBASE_MAP.md`
- `PLAN.md`
- `STATE.md`

### Execution Artifacts
Artifacts produced during implementation.
- `SUMMARY.md`

### Verification Artifacts
Artifacts that define or capture proof.
- `VALIDATION.md`
- `UAT.md`

## Artifact Catalog

### PROJECT.md
- **Purpose:** Define current project reality, priorities, and boundaries.
- **Producer:** Orchestrator / planner.
- **Consumers:** All stages.
- **Update triggers:** Scope changes, priority changes, product reality drift.
- **Must contain:** what this is, core value, active requirements, out of scope, key constraints.
- **Anti-patterns:** dumping every historical detail, mixing execution logs into strategy.

### DECISIONS.md
- **Purpose:** Lock durable technical and product decisions.
- **Producer:** Planner / architect.
- **Consumers:** Planner, implementer, verifier, reviewer.
- **Update triggers:** New decisions, reversals, superseded decisions.
- **Must contain:** decision id, rationale, owner, impact.
- **Anti-patterns:** undocumented reversals, temporary notes presented as durable decisions.

### CONTEXT.md
- **Purpose:** Freeze phase-specific scope boundaries and locked choices.
- **Producer:** Intake / discuss step.
- **Consumers:** Planner, checker, implementer.
- **Update triggers:** Only before implementation starts or after explicit re-discuss.
- **Must contain:** locked decisions, deferred items, technical constraints, acceptance shape.
- **Anti-patterns:** freeform notes with no clear locked vs optional distinction.

### RESEARCH.md
- **Purpose:** Capture domain knowledge, external patterns, and implementation guidance.
- **Producer:** Researcher / investigator.
- **Consumers:** Planner, checker.
- **Update triggers:** research pass, major architectural change.
- **Must contain:** standard approach, pitfalls, recommendations, sources.
- **Anti-patterns:** generic web notes, stale copy-paste without project relevance.

### CODEBASE_MAP.md
- **Purpose:** Describe brownfield structure and conventions.
- **Producer:** Mapper / investigator.
- **Consumers:** Planner, implementer, verifier.
- **Update triggers:** brownfield onboarding, major architecture drift.
- **Must contain:** system shape, architecture, conventions, shared contracts, integration points, risk zones.
- **Anti-patterns:** file inventory without architectural meaning.

### PLAN.md
- **Purpose:** Executable contract for a work packet.
- **Producer:** Planner.
- **Consumers:** Implementer, checker, verifier.
- **Update triggers:** planning and re-planning only.
- **Must contain:** requirements, dependencies, owned files, evidence commands, rollback, must-haves.
- **Anti-patterns:** vague tasks, missing verification, no file ownership.

### SUMMARY.md
- **Purpose:** Factual output of execution.
- **Producer:** Implementer.
- **Consumers:** Verifier, reviewer, orchestrator.
- **Update triggers:** after execution completes.
- **Must contain:** files changed, commands run, evidence produced, risks, rollback note.
- **Anti-patterns:** marketing language, unverifiable claims.

### VALIDATION.md
- **Purpose:** Define what must be proven.
- **Producer:** Planner / verifier.
- **Consumers:** Verifier, QA, reviewer.
- **Update triggers:** before verification or when repair scope changes proof expectations.
- **Must contain:** target goal, truths, artifacts, links, automated evidence, human checks.
- **Anti-patterns:** turning validation into a post-hoc summary.

### UAT.md
- **Purpose:** Capture human-only verification.
- **Producer:** Human + orchestrator.
- **Consumers:** Verifier, reviewer.
- **Update triggers:** user acceptance passes/fails.
- **Must contain:** test steps, expected behavior, observed result.
- **Anti-patterns:** vague 'looks good'.

### STATE.md
- **Purpose:** Track current workflow position and next valid actions.
- **Producer:** Orchestrator.
- **Consumers:** All stages.
- **Update triggers:** stage transition, block, resume, verification change.
- **Must contain:** current state, active phase, active plan, blockers, pending checks, next valid actions.
- **Anti-patterns:** diary-style logs, stale current state.

## Interaction Rules
- Strategic artifacts constrain operational artifacts.
- Operational artifacts constrain execution.
- Execution artifacts do not override strategic decisions by themselves.
- Verification artifacts evaluate outcomes against plans and requirements.
- Repair plans must roll forward from failed verification artifacts, not restart from scratch blindly.

## Compactness Rules
- Keep artifacts small enough to load directly into an agent.
- Move historical detail to archives or summaries when needed.
- If an artifact cannot be read quickly, it is no longer doing its job.
