# LLM-Guided Software Architecture

A production-grade development framework where AI agents build software with enterprise security, compiled contracts, self-improving pipelines, full observability, and zero ambiguity. Built for the 2026 toolchain: **OpenClaw + Claude Code + Codex**.

---

## What This Is

A drop-in methodology that turns natural language feature requests — or production incidents — into shipped, reviewed, tested, and audited code. The framework treats LLM-guided development as a **compiled, benchmarkable, self-improving system**, not a prompt playbook.

**Three tools. Clear responsibilities. No overlap.**

| Tool | Role | Invocation |
|------|------|------------|
| **OpenClaw** | Orchestrator — drives the workflow, manages issues/PRs, coordinates tools | Reads this README + `workflow.yaml` |
| **Claude Code** | Planner + Reviewer — analyzes codebase, produces plans, reviews PRs | `claude --print --prompt "/plan ..."` or `"/review ..."` |
| **Codex** | Implementer — writes code, runs tests, creates PRs | `codex --prompt "..." --full-auto` |

**What makes this different from other AI dev frameworks:**

1. **Compiled contracts** — Every phase output is validated against JSON schemas. Invalid plans don't reach implementation.
2. **Self-improving pipeline** — Review findings become lessons that feed future planning. The system gets smarter with every run.
3. **Spec-to-ship scorecard** — Every feature gets a quantitative score (0-100) comparing efficiency, quality, and reliability.
4. **Hybrid review** — Deterministic checks (secrets, scope, CVEs) run before LLM reasoning. Cheap coverage + deep analysis.
5. **Production closed loop** — Incidents and runtime drift trigger the same pipeline. Post-merge verification reopens issues on recurrence.
6. **Pipeline self-evals** — The framework tests itself. Template changes that break detection capabilities fail CI.

---

## For OpenClaw: Orchestrator Instructions

> This section is the **SOULS contract**. When the user says "follow the framework", read this section and `workflow.yaml` — they are your complete operating manual.

### Your Identity

You are the orchestrator for LLM-Guided Software Architecture. You drive the workflow defined in `workflow.yaml`. You **never write code yourself** — you delegate to Claude Code (planning/review) and Codex (implementation).

### How to Invoke Tools

**Claude Code — Planning:**
```bash
claude --print --prompt "/plan
[paste context: user request, codebase info, constraints, active lessons]
[ask for structured JSON output matching schemas/strategic-plan.schema.json]"
```

**Claude Code — Review:**
```bash
claude --print --prompt "/review
[paste context: PR number, issue requirements, scope, machine_findings from preflight]
[ask for structured findings matching schemas/review-output.schema.json]"
```

**Codex — Implementation:**
```bash
codex --prompt "
[paste: task spec, implementation steps, file scope, validation commands]
[instruct to commit, push, and create PR when done]
" --full-auto
```

**GitHub CLI:**
```bash
gh issue create --title "[TASK] Title" --body "$(cat issue_body.md)" --label "task"
gh pr create --title "Title" --body "Closes #N" --head "feat/#N-slug"
gh pr merge N --squash --delete-branch
gh issue close N --comment "Completed — PR #M merged"
```

### Auto-Configuration Protocol

When the user says "follow the framework" or starts a new project:

1. **Copy `AGENTS.md`** from this repo to the target project root
2. **Copy `schemas/`** directory to the target project
3. **Before /plan calls**: Copy `templates/CLAUDE_PLAN.md` to `{project}/CLAUDE.md`
4. **Before /review calls**: Copy `templates/CLAUDE_REVIEW.md` to `{project}/CLAUDE.md`
5. **For CI setup**: Copy `.github/workflows/code-review.yml` and `.github/workflows/pipeline-evals.yml` to `{project}/.github/workflows/`
6. **If heuristics packs apply**: Copy relevant pack from `packs/` to `{project}/packs/`
7. **Read `workflow.yaml`** and follow each phase in sequence
8. **For local monitoring**: Run `npx software-factory` in the project directory to open the dashboard UI

### The Workflow

The change class determines which phases run. Trigger source determines how the pipeline starts.

```
Trigger: user request | incident | runtime-drift
    |
    v
[1. INTAKE] -----> classify change, verify setup, load packs + lessons
    |
    |--- hotfix -------> [5*] → [6 hybrid] → [7+verify]           (fast path)
    |--- refactor -----> [2] → [5*] → [6 hybrid] → [7]            (4 phases)
    |--- feature ------> [2] → [3] → [4] → [5] → [6 hybrid] → [7] → [8]
    |--- risky-infra --> [2+ADR] → [3] → [4] → [5] → [6 thorough] → [7+verify] → [8]

    * = inline issue creation     + = with post-merge verification
```

| # | Phase | Tool | What happens |
|---|-------|------|-------------|
| 1 | Intake | OpenClaw | Classify change, load lessons + packs, verify setup |
| 2 | Strategic Plan | Claude Code /plan | Analyze codebase, produce task breakdown, ADRs if needed |
| 3 | Issue Creation | OpenClaw + gh | Create GitHub Issues (1 per task), link to parent |
| 4 | Tactical Plan | Claude Code /plan | Detailed implementation plan per issue |
| 5 | Implementation | Codex | Write code, run tests, create PR |
| 6 | Code Review | Preflight + Claude Code /review | Deterministic checks + LLM security/quality review |
| 7 | Merge & Close | OpenClaw + gh | Squash merge, close issue, post-merge verification |
| 8 | Completion | OpenClaw | Scorecard, lessons extraction, close parent issue |

**Contract validation gates:** After phases 2, 4, 6, and 8, outputs are validated against JSON schemas. Invalid outputs block progression and trigger retry.

See `workflow.yaml` for the complete specification.

### Observability & Audit Trail

Every action is logged. Every decision is recorded with rationale.

**Log file:** `.factory/workflow.log` (JSONL)
**Session state:** `.factory/session.json`
**Scorecard:** `.factory/scorecards/{session_id}.json`
**Lessons:** `.factory/lessons/`
**Report:** `.factory/REPORT.md`

```json
{
  "ts": "2026-04-02T14:00:00Z",
  "sid": "session-uuid",
  "phase": "strategic_plan",
  "action": "invoke_claude",
  "tool": "claude_code",
  "status": "ok",
  "duration_ms": 45000,
  "detail": "Strategic plan generated: 4 tasks across 2 waves",
  "decision": "Split into 4 tasks — auth + API + DB + tests need disjoint file ownership",
  "refs": {"issue": 42}
}
```

### Error Handling & Retry Policy

| Failure | Action |
|---------|--------|
| Schema validation fails | Retry phase with error context, then escalate |
| Planning fails | Retry 2x, then escalate to user |
| Implementation fails | Retry 2x with error context, then comment on issue |
| Review cycle exceeds max (3) | Comment on PR, escalate to user |
| Post-merge verification fails | Reopen issue with recurrence metadata |
| Tool unavailable | Wait 30s, retry with exponential backoff |

### Token Optimization

- **Fresh context per tool invocation** — do not carry conversation history between phases
- **Load only what the task needs** — AGENTS.md + relevant source files + active lessons
- **Prefer targeted reads** — grep/glob to find relevant code before reading entire files
- **Structured output** — JSON from all phases enables machine parsing without re-processing
- **Deterministic checks first** — cheap regex/script checks before expensive LLM review

### Human Escalation Rules

Escalate to user (do not proceed autonomously) when:
- Schema validation fails after retry
- Review finds CRITICAL security vulnerability with no clear fix
- Implementation fails after all retries
- Scope change requires product decision
- Post-merge verification fails repeatedly (recurrence > 2)
- Any action that would modify production infrastructure

---

## Core Principles

1. **Issue-First** — No code without a GitHub Issue. No branch without an issue number. No PR without `Closes #N`.
2. **Contract-Compiled** — Every phase output is validated against JSON schemas. Invalid outputs don't propagate.
3. **Evidence-First** — No "done" without proof. Build output, test results, review verdict, and scorecard are mandatory.
4. **Security-First** — Every plan includes threat assessment. Every review runs OWASP checks. Every PR has security section.
5. **Self-Improving** — Review findings become lessons. Lessons feed future planning. The pipeline gets smarter over time.
6. **Scope Discipline** — Explicit file boundaries per task. Disjoint ownership when parallelizing. No scope creep.

---

## Repository Contents

```
software-factory/
├── workflow.yaml                         # Core workflow engine (8 phases + routing)
├── AGENTS.md                             # Enterprise methodology (drop into any project)
├── README.md                             # This file (AI knowledge + SOULS instructions)
├── schemas/
│   ├── strategic-plan.schema.json        # Validates Phase 2 output
│   ├── tactical-plan.schema.json         # Validates Phase 4 output
│   ├── review-output.schema.json         # Validates Phase 6 output
│   ├── lesson.schema.json                # Validates extracted lessons
│   ├── scorecard.schema.json             # Validates spec-to-ship scorecard
│   └── heuristics-pack.schema.json       # Validates cross-project packs
├── templates/
│   ├── CLAUDE_PLAN.md                    # Planning mode contract (becomes CLAUDE.md)
│   ├── CLAUDE_REVIEW.md                  # Review mode contract (becomes CLAUDE.md)
│   ├── ISSUE_BODY.md                     # Issue body template for programmatic creation
│   └── ADR_TEMPLATE.md                   # Architectural Decision Record template
├── evals/
│   ├── run_evals.py                      # Self-eval runner
│   ├── README.md                         # Eval documentation
│   ├── plans/                            # Plan fixtures (valid + invalid)
│   └── diffs/                            # Adversarial PR diff fixtures
├── packs/
│   └── pack-saas-api.json                # Example heuristics pack for SaaS APIs
├── dashboard/
│   ├── server.js                         # Express server + API + SSE
│   ├── public/                           # Vanilla HTML/CSS/JS frontend (7 views)
│   └── package.json                      # npx software-factory to run
├── docs/
│   ├── LOGGING.md                        # Enterprise logging standard (pipeline + application)
│   └── METRICS.md                        # Scorecard formula and interpretation
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── implementation_task.yml       # SDD-grade issue template
│   ├── PULL_REQUEST_TEMPLATE.md          # 12-section PR template with security review
│   └── workflows/
│       ├── code-review.yml               # Automated hybrid review action
│       └── pipeline-evals.yml            # Self-eval CI for schema/template changes
└── .gitignore
```

---

## Change Classes

The change class is the **single decision that controls process weight**. Choose honestly.

| Class | When | Phases | Security | Extras |
|-------|------|--------|----------|--------|
| `hotfix` | Production is broken | intake → implement → review → merge | Diff-only check | Inline issue, post-merge verify |
| `feature` | New functionality | Full 8-phase pipeline | Proportional to risk | Scorecard + lessons |
| `refactor` | Code improvement | intake → plan → implement → review → merge | Regression focus | Single issue |
| `risky-infra` | Infrastructure changes | Full 8-phase + thorough review | Full OWASP + threat model + ADR | Post-merge verify |

## Trigger Sources

| Source | When | Extra Context |
|--------|------|--------------|
| `user` | User requests a feature or fix | User description only |
| `incident` | Monitoring alert (Sentry, PagerDuty) | Error fingerprint, stack trace, affected service |
| `runtime-drift` | Watchdog detects operational drift | Health check results, expected vs actual state |

---

## Common Pitfalls

| Pitfall | Rule |
|---------|------|
| Code without an issue | Every task starts with a GitHub Issue |
| Planning without reading code | ALWAYS read the codebase before planning |
| Two agents editing same file | One owner per file — disjoint file scope |
| Saying "done" without evidence | Build + test output required in every PR |
| Skipping schema validation | Every phase output MUST validate against its schema |
| Ignoring lessons from past runs | Load `.factory/lessons/` before every planning phase |
| Testing on localhost only | Validation must hit production path |
| Pushing through when plan fails | STOP and re-plan — do not keep retrying the same approach |
| Scope creep during implementation | Only modify files listed in issue's scope |

---

## License

MIT
