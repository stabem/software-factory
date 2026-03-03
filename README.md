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

### How to Use the Task Packet Template (Detailed)

Use one packet **per delegated task** (not per project). A good packet removes ambiguity.

1. **Copy the template** into your task/issue/PR comment.
2. Fill `Outcome` with a testable sentence (avoid vague goals).
3. Fill `In Scope` with exact paths the agent can touch.
4. Fill `Out of Scope` with protected files/areas.
5. Fill `Validation` with exact commands (build/test/smoke).
6. Before execution, confirm packet with the orchestrator/human.
7. After execution, reject any delivery missing evidence.

#### Good packet example
```markdown
## Outcome
Add `/healthz` endpoint returning `{ "status": "ok" }` with 200.

## In Scope
- src/routes/health.ts
- src/server.ts
- tests/health.test.ts

## Out of Scope
- billing/
- auth/
- database schema/migrations

## Validation
- npm run build
- npm test -- health.test.ts
- curl -i http://localhost:3000/healthz

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

## What We Incorporated from Real-World Swarm Operations

Based on production use of orchestrated Codex/Claude/Gemini-style swarms, we add these practical rules:

### 1) PR is not Done
A PR link is a milestone, not completion.
Completion requires:
- branch rebased/synced with default branch
- CI green
- blocking review comments resolved
- UX evidence for UI changes

### 2) Use a Task Registry + Deterministic Monitor
Track worker state in a machine-readable registry (JSON/YAML).
Run a low-cost monitor loop (cron) to check:
- worker liveness
- PR existence
- check status
- retry budget

This is cheaper and more reliable than repeatedly asking an LLM for status.

### 3) Reviewers Should Be Complementary
Use different reviewer strengths (correctness, security/scalability, sanity check).
Gate merges only on `critical` findings.

### 4) Respect Hardware Limits
Swarm throughput is often bounded by RAM/IO before model limits.
Define per-host concurrency budgets and stagger heavy build/test jobs.

### 5) Human Escalation by Exception
Alert the human only when intervention is required (failed retries, conflicting reviews, product decision).
Default path should be autonomous.

---

### Reference implementation in this repo
- `templates/swarm.tasks.example.json`
- `scripts/check-swarm.sh`
- `docs/SWARM_RUNBOOK.md`

### How to Use `templates/swarm.tasks.example.json` (Detailed)

This file is the machine-readable registry for swarm execution.

#### 1) Bootstrap your registry
```bash
cp templates/swarm.tasks.example.json .swarm/tasks.json
```

#### 2) Configure defaults once
Edit `.swarm/tasks.json`:
- `maxRetries`: retries before human escalation
- `requiredChecks`: checks that must be green (`review`, `ci`, etc.)
- `requirePr`: force PR gate before done
- `requireMerged`: require merged PR before done
- `requireDeployValidation`: require deployment validation evidence before done

#### 3) Add one entry per task
For each delegated task, append a `tasks[]` object with:
- stable `id` (e.g. `task-013`)
- clear `title`
- `branch`
- `owner` (agent/harness)
- `session` info (tmux/acp/etc)

#### 4) Drive status transitions
Use strict lifecycle states:
- `queued` -> `running` -> `done`
- or `blocked` when waiting on decision/review

Never jump directly to `done` on PR creation; only after required checks,
merge gate (if enabled), and deploy validation gate (if enabled).

#### 5) Keep PR/check fields updated
As work progresses, update:
- `pr.number`, `pr.url`, `pr.state`
- `checks.review`, `checks.ci`
- `retries`
- `notes` (short reason for block/failure/retry)

#### 6) Monitoring rule
Run monitor on schedule (5–10 min):
- if worker died: retry (up to `maxRetries`)
- if PR missing for `running` task: flag as `blocked`
- if checks failed: keep `running/blocked`, not `done`
- if checks are green but merge/deploy gates are pending: keep `running`
- mark `done` only when all required gates are satisfied

#### Minimal completed-task example
```json
{
  "id": "task-013",
  "title": "Add health endpoint",
  "status": "done",
  "branch": "feat/health-endpoint",
  "owner": "agent-codex",
  "session": { "type": "tmux", "name": "swarm-task-013" },
  "pr": {
    "number": 128,
    "url": "https://github.com/org/repo/pull/128",
    "state": "MERGED",
    "mergedAt": "2026-02-24T14:31:00Z"
  },
  "checks": { "review": "passed", "ci": "passed" },
  "deploy": {
    "validated": true,
    "environment": "production",
    "evidence": "https://grafana.example.com/d/abc123"
  },
  "retries": 1,
  "notes": "Merged and validated in production path."
}
```

## Delivery Governance Add-ons (High-Rigor Teams)

### Definition of Ready (DoR)
Before execution starts, the task must be "ready":
- problem statement with evidence
- in-scope / out-of-scope files
- explicit validation commands
- rollback command
- NFR targets (latency/cost/security/observability)

If any DoR item is missing, keep task as `queued`.

### Change Classes (proportional process)
Use a class per task to scale rigor:
- **hotfix**: fastest path, mandatory post-incident review
- **feature**: full plan + verify + PR gate
- **refactor**: must show no-regression evidence
- **risky-infra**: requires rollout + rollback drills

### NFR/SLO Gate (mandatory for production-impacting work)
Before marking done, verify and record:
- performance budget impact
- reliability/SLO impact
- security impact
- cost impact
- observability coverage (logs/metrics/alerts)

### Incident Severity Matrix
- **P0**: total outage/data loss, immediate human escalation
- **P1**: critical feature degraded, owner + mitigation ETA required
- **P2**: partial degradation, fix in planned sprint
- **P3**: minor issue, backlog with owner

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

### Plan-Mode Protocol (Required)
For non-trivial work, enforce model specialization:

1. Run **Claude Code in Plan Mode** to produce the implementation plan (no code edits).
2. Approve/freeze plan scope.
3. Run **Codex 5.3** to implement exactly that plan.
4. Attach build/test/smoke evidence before opening/merging PR.

**Rules:**
- No implementation before a written plan.
- Scope changes require returning to Plan Mode.
- If tool routing is limited, keep the same discipline manually (plan first, then implement).

#### Plan -> Implement Handoff Artifact
Before Codex implementation starts, freeze this handoff block in the task/PR:

1. Approved plan version/hash
2. In-scope files
3. Out-of-scope files
4. Required validation commands
5. Rollback command

If any item changes, go back to Plan Mode and issue a new handoff.

#### Channel/Runtime Fallback
When your chat/runtime cannot keep persistent threaded harness sessions (some surfaces do not support thread binding), keep the protocol:
- run planning as a one-shot **Plan Mode** turn,
- approve/freeze scope,
- run implementation as a separate **Codex 5.3** turn,
- keep both artifacts linked in the PR.

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

A concrete run from production, using the exact workflow above.

### Problem
New users were dropping before activation.

### Baseline (Investigate)
- Cohort query: **17 / 35 users (49%)** never verified email.
- All affected users got **403** on first API calls.
- Root cause: token was created at signup, but verification email was never sent.

### Plan (before code)
Approved plan split into isolated packets:
- `p0-backend`: send verification email + improve 403 error payload + resend endpoint
- `p0-frontend`: verification banner + onboarding checklist + demo fallback
- `p1p2-backend`: reminder/milestone/win-back email jobs

Guardrails used:
- one file owner per packet
- explicit in-scope / out-of-scope files
- build/test commands attached to each packet

### Execute
- Agents ran in parallel on disjoint scopes.
- One packet hit a type assertion regression; detected immediately by build evidence and fixed before integration.

### Verify (evidence-based)
End-to-end flow tested on production path:
1. signup
2. verification email delivery
3. verification link resolution
4. dashboard state refresh
5. API access works after verify

Additional regressions found and fixed during verify:
- stale auth/cache state after verification
- SPA route intercepting verify callback
- frontend consuming missing API field without guard

### Learn
- Added 5 lessons to `tasks/lessons.md`
- Promoted 3 recurring failures to **Common Pitfalls**

### Outcome
- Verification delivery: **0% -> 100%** for new signups in validation window
- Activation blocker removed
- Rollout shipped via PR gate with review + green checks

---

## More Real-World Scenarios (Copy/Paste)

### Scenario A — Runtime incident on third-party API (503 spikes)

**Investigate**
- Capture 30–60 min logs with timestamps.
- Confirm whether failures are internal or upstream (direct `curl` from host + from container).
- Check if service auto-recovers without restart.

**Plan**
- Add alert hysteresis (ex: alert only after N consecutive failures).
- Add classification: `upstream-transient`, `auth-failure`, `internal-bug`.
- Define rollback: disable new alert rule via env flag.

**Execute**
- Implement error counters + decay window.
- Improve log context (`endpoint`, `status`, `retry_count`, `component`).
- Keep existing execution path unchanged (minimal blast radius).

**Verify**
- Replay with synthetic 503 bursts.
- Ensure one-off failures do not page.
- Ensure sustained failure still pages.

**Learn**
- Document final thresholds and rationale in `tasks/lessons.md`.

---

### Scenario B — Feature delivery with strict plan/implement split

**Plan Mode output (Claude) must include:**
- problem + root cause hypothesis
- exact file list (in/out of scope)
- implementation checklist
- validation commands
- rollback command

**Codex implementation gate:**
- starts only after plan is approved/frozen
- cannot add out-of-scope files without re-plan
- returns: changed files + command outputs + residual risks

**Definition of done:**
- PR merged
- required checks green
- review comments resolved
- deploy validation recorded on production path

---

### Scenario C — Regression after deploy

**Investigate first (no hotfix guessing):**
- compare pre/post deploy metrics
- identify first bad commit/release window
- check cache/token invalidation side effects

**Plan**
- immediate mitigation (feature flag/revert)
- permanent fix
- post-fix validation suite

**Execute**
- apply mitigation in smallest possible diff
- ship permanent fix behind guard if needed

**Verify**
- regression test reproducer now passes
- no new errors in adjacent flows

**Learn**
- add a new guardrail/test so this exact failure cannot recur silently

---

## How to Implement This Methodology in a New Repo (Detailed)

### Day 0 (bootstrap)
1. Add `AGENTS.md` to repo root.
2. Create `tasks/todo.md` and `tasks/lessons.md`.
3. Add PR template with: root cause, changed files, validation, rollback.
4. Enable required checks in branch protection.

### Day 1 (first task)
1. Run one full cycle: INVESTIGATE → PLAN → EXECUTE → VERIFY.
2. Keep plan/implement artifacts in PR body.
3. Record at least one lesson in `tasks/lessons.md`.

### Week 1 hardening
1. Introduce task packet contract for delegated work.
2. Add deterministic monitor (script/cron) for worker/PR/check status.
3. Cap parallel workers (default max 3) and enforce file ownership boundaries.
4. Track cycle time + escaped defects; tune process with evidence.

### Golden operating rules
- No plan -> no implementation.
- No evidence -> task not done.
- No PR -> not shipped.
- If scope changes -> back to Plan Mode.

---

## License

MIT — use it however you want.
