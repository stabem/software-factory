# AGENTS.md — Software Factory Methodology

> Drop this file into any project root. Every AI agent that reads it inherits the full development workflow.

---

## The 5 Phases

Every non-trivial task follows this cycle:

```
INVESTIGATE → PLAN → EXECUTE → VERIFY
     ↑                              |
     └──── LEARN (always) ──────────┘
```

---

## Phase 1: INVESTIGATE 🔍

**Before writing a single line of code or plan, understand the problem with DATA.**

- Query the database. Check real user behavior, not assumptions.
- Read the relevant code. Understand the architecture before changing it.
- Check logs, error rates, actual traffic patterns.
- Look at the full production path (external URLs, not just localhost).
- Identify the REAL root cause, not the symptom.

**Investigation checklist:**
- [ ] Queried DB for real numbers
- [ ] Read the relevant source files
- [ ] Checked logs/errors for the actual failure mode
- [ ] Tested the production path (not just dev/localhost)
- [ ] Identified root cause vs symptom

---

## Phase 2: PLAN 📋

**Write a plan BEFORE touching code. The plan is a contract.**

**When to plan (mandatory):**
- Any task with 3+ steps
- Any architectural decision
- Any task involving multiple files or services
- Any task delegated to sub-agents

**Plan structure:**
1. **Problem statement** — what's broken, with data
2. **Root cause** — why it's broken
3. **Solution spec** — exact files, exact changes, exact behavior
4. **Task breakdown** — checkable items in `tasks/todo.md`
5. **Agent assignment** — who does what (if parallelizing)
6. **Verification criteria** — how we know it's done

**Rules:**
- If something goes sideways during execution → STOP and re-plan. Don't push through.
- Write detailed specs upfront to reduce ambiguity for sub-agents.
- Every plan item should be independently verifiable.

---

## Phase 3: EXECUTE ⚡

**Build the thing. Use sub-agents for parallelism.**

### Sub-Agent Rules (Critical)

1. **One file owner per agent** — NEVER let two agents touch the same file in parallel. If two agents need the same file, sequence them.
2. **One task per agent** — Focused execution beats multi-tasking.
3. **Explicit file boundaries** — Every sub-agent spec must list which files it CAN and CANNOT touch.
4. **Build + smoke test** — Every sub-agent MUST build/compile AND verify output before reporting done. A "completed" task that doesn't compile is NOT completed.

### Sub-Agent Spec Template

```markdown
## Task: [Name]

### Context
[Brief description of the project, stack, architecture]

### Tasks (in order):
1. [Specific change with file path and line numbers if known]
2. [...]

### Build & Test
[Exact commands to verify the work]

### DO NOT:
- [Files/systems this agent must not touch]
- [Patterns to avoid]
```


## Orchestrator-First Swarm Layer 🤖

Treat the assistant as an **orchestrator** (not the coder of every task).

### Operating model
- Main orchestrator receives business request, clarifies outcome, and designs the execution plan.
- Work is split into focused task packets and delegated to specialized agents/tools.
- Orchestrator validates, integrates, and decides ship/no-ship based on evidence.

### Task Packet Contract (required for every delegated task)
1. **Outcome** — exact expected result
2. **Scope** — files/services in scope
3. **Out of scope** — explicit do-not-touch list
4. **Validation** — exact build/test commands + expected signals
5. **Rollback note** — how to revert safely

### Model/Agent Routing Rules
- **Architecture/risk-sensitive tasks** → strongest reasoning model/agent.
- **Mechanical refactors/migrations** → fast code model/agent.
- **Research/exploration** → cheap parallel workers, then synthesis by orchestrator.
- Always log *why* a model/agent was chosen in PR notes for repeatability.

### Concurrency Budget
- Run parallel agents only when file ownership is disjoint.
- Define a max concurrent worker count per repo (default 3).
- If integration conflicts rise, reduce parallelism before changing code strategy.

### Evidence-First Completion
A delegated task is complete only when it returns:
- changed file list
- test/build output
- risk notes
- rollback command

No evidence = not done.

---
---

## Phase 4: VERIFY ✅

**Never mark a task complete without proving it works.**

- Run the build. Check for compilation errors.
- Test the actual user flow end-to-end (E2E).
- Test the **production path** (external URLs, CDN, proxies) — not just localhost.
- Diff behavior between before and after.
- Check for side effects (did we break something else?).

**E2E Verification checklist:**
- [ ] Build passes
- [ ] Feature works on localhost
- [ ] Feature works on production URL
- [ ] No regressions (existing features still work)
- [ ] Error cases handled gracefully

---

## Phase 4.5: PR GATE 🔐 (Mandatory)

After implementation/verification, PR is required before deploy:

1. Create branch from default branch (`main` or `master`)
2. Commit scoped changes
3. Push and open PR
4. Wait for Guardian/Codex automated review
5. Address all requested changes
6. Re-run review until no blocking findings
7. Merge after checks pass
8. Deploy only from merged default branch

Org standard:
- Use reusable workflows from `stabem/.github` when available
- Require status check `review`
- Require at least one approval

For `bybit-agents` and `content-api`, this step is non-negotiable.

## Pricing/Billing Guardrail 🔒

- Never create/rename/remove commercial plans without explicit owner approval.
- Do not infer new Stripe SKUs from technical rate-limit/quota work.
- Before touching plan logic, validate current project pricing and billing wiring.
- PR must explicitly state: "No new commercial plan created" when only technical limits are adjusted.

## Phase 5: LEARN 🧠 (Always)

**Every mistake becomes a rule. Every surprise becomes a lesson.**

After ANY correction, failure, or unexpected behavior:

1. **Document it** in `tasks/lessons.md` with:
   - **Problem:** What went wrong
   - **Lesson:** What we learned
   - **Rule:** Concrete rule to prevent repetition
2. **Review lessons** at the start of every work session
3. **Promote patterns** — if a lesson applies broadly, add it to the pitfalls table

---

## Task Management

**Files:**
- `tasks/todo.md` — active checklist (one per workspace or per-project)
- `tasks/lessons.md` — accumulated lessons learned (never delete, only add)

**Workflow:**
1. Write plan to `tasks/todo.md` with checkable items
2. Check in with user before starting (for major work)
3. Mark items `[x]` as you go
4. Add review section after completion
5. Update `tasks/lessons.md` after ANY correction or surprise

---

## Core Principles

- **Investigate with Data:** Query DB, check logs, look at real behavior BEFORE planning.
- **Simplicity First:** Make every change as simple as possible. Minimal code impact.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Changes should only touch what's necessary.
- **Autonomous Bug Fixing:** Given a bug report, just fix it. No hand-holding needed.
- **Text > Brain:** Write things down. Mental notes don't survive sessions.

---

## Common Pitfalls

| Pitfall | Rule |
|---------|------|
| Two sub-agents editing same file | One owner per file. Sequence if needed. |
| Sub-agent says "done" but build fails | Every spec ends with build + smoke test. |
| Testing on localhost, broken in prod | E2E tests MUST hit production URLs. |
| Planning fixes before investigating | ALWAYS query DB + check logs first. |
| Pushing through when plan fails | STOP and re-plan. Don't keep pushing. |
| "Mental notes" about things to remember | Write it to a file. Text > Brain. |
| Cache/state not refreshed after mutation | Invalidate caches + refresh tokens after state changes. |
| Orchestrator becomes bottleneck | Force task packets + evidence contracts; orchestrator reviews, not rewrites. |
| Too many parallel agents create merge noise | Cap concurrency (default 3) and enforce disjoint ownership. |
| Agent/model choice is random | Route by task type and record rationale in PR notes. |
| Delegated work marked done without proof | Require changed files + test logs + rollback note. |
