# 🏭 Software Factory

A battle-tested development methodology for AI-assisted software development. Built from real production experience shipping SaaS products with AI agents.

**Not theoretical.** Every rule here exists because we hit the problem first.

---

## What This Is

A drop-in methodology for any project where AI agents build software. It works with:
- Claude Code, Codex CLI, OpenCode, Cursor, Windsurf
- OpenClaw sub-agents
- Any LLM-based coding workflow

**Core idea:** Treat AI agents like junior-to-mid engineers on your team. They're fast but need clear specs, explicit boundaries, and verification. This system provides the structure.

## Quick Start

1. Copy `AGENTS.md` into your project root
2. Create `tasks/todo.md` and `tasks/lessons.md`
3. Start following the 5-phase cycle
4. Use **PR-first delivery**: every implementation ends in a Pull Request (no direct pushes to main)

That's it. Everything else is optional.

---

## PR-First Delivery Loop (Required)

For production repos, treat PR creation as part of "done":

1. Implement changes on a feature branch
2. Run build/tests + smoke checks
3. Push branch and open PR with:
   - root cause
   - exact files changed
   - verification commands/output
   - risk/rollback notes
4. Let review automation/humans comment (Codex/CI/reviewer)
5. Apply fixes in the same PR until green
6. Merge only after checks pass
7. Deploy and validate in production path

**Rule:** If there is no PR, the task is not complete.


---


## Orchestrator + Agent Swarm Pattern

For one-person teams using multiple AI coding agents, adopt an **orchestrator-first** architecture:

1. **Orchestrator plans** the work (problem, root cause, spec, acceptance criteria)
2. **Delegates task packets** to specialized agents/tools
3. **Collects evidence** (changed files, test logs, risk notes, rollback)
4. **Integrates + verifies** before PR

### Task Packet Template (copy/paste)
```markdown
## Outcome
[Exact expected result]

## In Scope
- path/to/fileA
- path/to/fileB

## Out of Scope
- path/to/fileC

## Validation
- [command 1]
- [command 2]

## Deliverables
- changed files list
- test/build output
- risk notes
- rollback command
```

### Routing Heuristics (model/agent choice)
- **Complex architecture / high-risk**: strongest reasoning model
- **Refactor / repetitive edits**: fast coding model
- **Research / option discovery**: parallel cheap workers + orchestrator synthesis

### Reliability Ops for External Integrations
If your workflow depends on authenticated scraping/extraction (e.g., X article full-text):
- define a canary check (hourly)
- alert when extraction quality drops (e.g., text length threshold)
- keep a documented session refresh runbook
- persist auth/session state in env/config so restarts do not silently degrade behavior

This avoids hidden drift where “pipeline is green” but business data quality is broken.

---
## The 5-Phase Cycle

Every non-trivial task follows this cycle:

```
INVESTIGATE → PLAN → EXECUTE → VERIFY
     ↑                              |
     └──── LEARN (always) ──────────┘
```

### Phase 1: INVESTIGATE 🔍

**Before writing a single line of code, understand the problem with DATA.**

- Query the database. Check real user behavior, not assumptions.
- Read the relevant code. Understand the architecture before changing it.
- Check logs, error rates, actual traffic patterns.
- Look at the full production path (external URLs, not just localhost).
- Identify the REAL root cause, not the symptom.

**Anti-pattern:** "Users aren't converting → must be bad onboarding UX"  
**Correct:** "Users aren't converting → 49% can't verify email → they're BLOCKED, not confused"

**Investigation checklist:**
- [ ] Queried DB for real numbers
- [ ] Read the relevant source files
- [ ] Checked logs/errors for the actual failure mode
- [ ] Tested the production path (not just dev/localhost)
- [ ] Identified root cause vs symptom

### Phase 2: PLAN 📋

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

### Phase 3: EXECUTE ⚡

**Build the thing. Use sub-agents for parallelism.**

See [Sub-Agent Rules](#sub-agent-rules) below — this is where most mistakes happen.

### Phase 4: VERIFY ✅

**Never mark a task complete without proving it works.**

- Run the build. Check for compilation errors.
- Test the actual user flow end-to-end (E2E).
- Test the **production path** (external URLs, CDN, proxies) — not just localhost.
- Check for side effects (did we break something else?).

**E2E Verification checklist:**
- [ ] Build passes
- [ ] Feature works on localhost
- [ ] Feature works on production URL
- [ ] No regressions
- [ ] Error cases handled gracefully
- [ ] PR opened with validation evidence
- [ ] PR checks/review feedback resolved before merge

### Phase 4.5: PR GATE (MANDATORY) 🔐

**No direct deploy after local implementation. Every change must go through PR first.**

Required flow (mandatory for all repos, critical for `bybit-agents` and `content-api`):
1. Create branch from default branch (`main` or `master`)
2. Commit with clear scope
3. Push branch
4. Open PR with test evidence and rollout notes
5. Wait for automated Guardian/Codex review comments
6. Apply required fixes, push updates
7. Re-run review until no blocking findings
8. Merge only when checks/review are green
9. Deploy from merged default branch only (never from unreviewed branch)

**Automation pattern (org-wide):**
- Reusable workflow for review (`guardian-review`)
- Optional reusable workflow for conditional auto-approval (`guardian-approve`)
- Branch protection requires review check + at least 1 approval

**PR checklist (copy into PR body):**
- [ ] Root cause documented
- [ ] Fix implemented with minimal scope
- [ ] Build/test evidence included
- [ ] User-path verification included
- [ ] Monitoring/Sentry impact noted
- [ ] Rollback plan included

### Pricing/Billing Guardrail (Mandatory)

- Never introduce or assume new commercial plans (Stripe/pricing tiers) without explicit owner approval.
- Technical throttling/quota changes must map to **existing** project plan definitions.
- If legacy/deprecated plan labels exist in code, clarify in PR body that no new SKU is being created.
- Any pricing/billing change requires dedicated PR section: current state, proposed change, Stripe impact, rollback.

### Phase 5: LEARN 🧠

**Every mistake becomes a rule. Every surprise becomes a lesson.**

After ANY correction, failure, or unexpected behavior:

1. Document it in `tasks/lessons.md`
2. Review lessons at the start of every work session
3. Promote patterns to the pitfalls table when broadly applicable

---

## Sub-Agent Rules

This is where projects fail. These rules are non-negotiable.

### The Golden Rules

| Rule | Why |
|------|-----|
| **One file owner per agent** | Two agents editing the same file = merge conflicts, reverted changes, subtle bugs |
| **One task per agent** | Focused execution beats multi-tasking |
| **Every agent builds + tests** | "Done" means it compiles and runs, not "I wrote the code" |
| **Explicit file boundaries** | Every spec lists which files the agent CAN and CANNOT touch |

### Sub-Agent Spec Template

Every sub-agent task MUST include:

```markdown
## Task: [Name]

### Context
[Brief description of the project, stack, architecture]

### Tasks (in order):
1. [Specific change with file path]
2. [...]

### Build & Test
[Exact commands to verify the work]

### DO NOT:
- [Files/systems this agent must not touch]
- [Patterns to avoid]
```

**Why this matters:** Without explicit boundaries, agents will "helpfully" modify files outside their scope, breaking other agents' work. We learned this the hard way.

---

## File Structure

```
your-project/
├── AGENTS.md              # ← Drop this in (full methodology)
├── tasks/
│   ├── todo.md            # Active task tracking
│   └── lessons.md         # Accumulated lessons (append-only)
└── ... your code ...
```

### `AGENTS.md`

The main file. Contains the full methodology that any AI agent reads at session start. Drop it into any project root and every agent inherits the workflow automatically.

**Key property:** Project-agnostic. Works for Go APIs, React frontends, Python scripts, anything. You never need to re-explain the methodology — agents read AGENTS.md and know how to work.

### `tasks/todo.md`

Active task tracking. One per project (or per sprint).

```markdown
# [Project Name] — Active Tasks

## Phase: [Investigation | Planning | Execution | Verification]

### Current Sprint
- [ ] Task 1 — [brief description]
- [ ] Task 2 — [brief description]
- [x] Task 3 — [completed]

### Blocked
- [ ] Task 4 — blocked on [reason]

### Review
[Post-completion notes, what worked, what didn't]
```

### `tasks/lessons.md`

Accumulated lessons. **Append-only — never delete, only add.**

```markdown
# Lessons Learned

## [Category]

### [Short title]
- **Problem:** What went wrong
- **Lesson:** What we learned
- **Rule:** Concrete rule to prevent repetition
```

---

## Common Pitfalls

From real production experience:

| Pitfall | Rule |
|---------|------|
| Two sub-agents editing same file | One owner per file. Sequence if needed. |
| Sub-agent says "done" but build fails | Every spec ends with build + smoke test command. |
| Testing on localhost, broken in prod | E2E tests MUST hit production URLs (CDN, proxies, DNS). |
| Planning fixes before investigating | ALWAYS query DB + check logs first. |
| Pushing through when plan fails | STOP and re-plan. Don't keep hacking. |
| "Mental notes" about things to remember | Write it to a file. Memory doesn't survive sessions. |
| Cache/state after mutations | State changes (email verify, role change) → invalidate caches + refresh tokens. |
| SPA routing vs API routing | Verify the full production path: CDN → reverse proxy → backend. SPAs catch-all routes intercept API paths. |
| Assuming API responses have all fields | Check the actual response struct. Missing fields = `undefined` on frontend = silent bugs. |

---

## Philosophy

- **Investigate with Data:** Query DB, check logs, look at real behavior BEFORE planning. Assumptions kill projects.
- **Simplicity First:** Make every change as simple as possible. Minimal code impact.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Autonomous Bug Fixing:** When given a bug report, just fix it. Point at logs, errors, failing tests — then resolve them.
- **Text > Brain:** If you want to remember something, write it to a file. Mental notes don't survive session restarts.

---

## Real-World Example

Here's how this methodology was used to fix a 49% user drop-off in a SaaS API:

**INVESTIGATE:** Queried DB → 17 of 35 users never verified email → all got 403 on every API call. The verification token was generated at signup but **never emailed**.

**PLAN:** Created 3 parallel sub-agents:
- `p0-backend` — verification email, improved 403 message, resend endpoint
- `p0-frontend` — verification banner, getting started checklist, demo fallback
- `p1p2-backend` — reminder emails, milestone emails, win-back emails

Each agent had explicit file ownership — no overlapping files.

**EXECUTE:** All 3 agents ran in parallel (~2 min each). One agent introduced a type assertion bug in a shared file — caught because we have the "one file owner" rule and the other agent's build failed.

**VERIFY:** Full E2E test: signup → emails arrived → clicked verify link → dashboard updated → API calls worked. Found 3 more bugs (cache not invalidating, verify link routing through SPA, missing field in API response). Fixed all.

**LEARN:** 5 new lessons added to `tasks/lessons.md`, 3 promoted to the pitfalls table.

**Result:** 0% → 100% of new signups now receive verification email. Drop-off eliminated.

---

## License

MIT — use it however you want.
