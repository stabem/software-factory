# AGENTS.md — LLM-Guided Software Architecture

> Drop this file into any project root. Every AI agent that reads it inherits the full development methodology with enterprise security and quality standards.

---

## The Three-Tool Architecture

| Tool | Responsibility | Hard Boundary |
|------|----------------|---------------|
| **OpenClaw** | Orchestration, issue/PR management, workflow coordination | Never writes code |
| **Claude Code** | Strategic/tactical planning, code review | Never implements — only plans and reviews |
| **Codex** | Code implementation, testing, PR creation | Only modifies files explicitly listed in scope |

---

## The Development Pipeline

Every task follows this pipeline. No shortcuts, no skipping phases.

```
INTAKE → PLAN → IMPLEMENT → REVIEW → MERGE
```

- **INTAKE**: Receive request, classify change type
- **PLAN**: Analyze codebase, produce structured plan with security assessment
- **IMPLEMENT**: Write code following the plan, run tests, create PR
- **REVIEW**: Security + quality review, fix findings, re-review
- **MERGE**: Squash merge, close issue with evidence

---

## Issue-First Development (Non-Negotiable)

Every code change starts with a GitHub Issue. No exceptions.

**Rules:**
1. Create GitHub Issue BEFORE writing any code
2. The issue IS the specification — fill every section
3. Branch name references issue: `feat/#42-description` or `fix/#55-description`
4. Every PR starts with: `Closes #<issue-number>`
5. Issue closes AFTER merge + validation — not when PR opens

**Why:** Without an issue, there is no specification, no acceptance criteria, no scope boundary, and no traceability. Code without an issue is untracked work.

---

## PR Gate (Mandatory)

No direct pushes to main. Every change goes through a PR.

**Required in every PR:**
1. Issue reference (`Closes #N`)
2. Summary of changes
3. Validation evidence (build output, test results)
4. Security review section (completed, not rubber-stamped)
5. Rollback plan (specific commands, not "revert changes")

**Merge conditions:**
- Review verdict: APPROVE
- CI checks: all passing
- No unresolved CRITICAL findings

---

## Change Classes

The change class controls how much process is applied. Heavier process only when the risk justifies it.

| Class | Phases | Security Gate | PR Body |
|-------|--------|---------------|---------|
| `hotfix` | implement → lightweight review → merge | Diff-only security check | Summary + validation evidence |
| `feature` | Full 8-phase pipeline | Proportional to security risk level | Full template |
| `refactor` | plan → implement → review → merge | Regression focus, security only if touching auth/data | Summary + no-regression evidence |
| `risky-infra` | Full 8-phase + thorough review | Full OWASP audit + threat model | Full template + rollback drill |

**Rule:** The change class is chosen at intake and determines the routing. If during implementation you realize the risk is higher than classified, **stop and reclassify** — don't keep going with a lightweight process on a risky change.

---

## Enterprise Security Standards

### Secure Coding Rules (All Changes)

- **Parameterized queries only** — no SQL string concatenation with user input
- **Input validation at system boundaries** — validate type, format, length, range
- **No eval() with user input** — no `eval()`, `exec()`, `Function()`, `new Function()` with external data
- **No hardcoded secrets** — credentials, API keys, tokens loaded from environment or vault
- **Output encoding** — all user content encoded before rendering in HTML
- **Least privilege** — request minimum permissions, use read-only DB connections where possible
- **Dependency hygiene** — pin versions, no deps with known HIGH/CRITICAL CVEs

### OWASP Top 10 Awareness

Every plan and review must consider:

1. **Broken Access Control** — verify auth on every endpoint, enforce ownership
2. **Cryptographic Failures** — encrypt sensitive data at rest and transit, no deprecated algorithms
3. **Injection** — parameterized queries, input validation, output encoding
4. **Insecure Design** — threat model for medium+ risk changes
5. **Security Misconfiguration** — CSP headers, CORS policy, no default credentials
6. **Vulnerable Components** — dependency scanning, version pinning
7. **Authentication Failures** — strong password hashing, session management, MFA support
8. **Data Integrity Failures** — verify update/deploy pipelines, sign artifacts
9. **Logging Failures** — log security events, never log secrets or PII
10. **SSRF** — validate URLs, block internal IP ranges

### Secrets Management

```
ALLOWED: Environment variables, vault (HashiCorp, AWS Secrets Manager, Azure Key Vault)
FORBIDDEN: Source files, config files in repo, hardcoded constants, comments, commit messages
```

Files that must NEVER be committed:
```
.env, .env.*, *.pem, *.key, *.p12, credentials.json, secrets.yaml, service-account.json
```

---

## Code Quality Standards

### Testing Pyramid

```
         /  E2E  \        ~5% of tests — critical user flows only
        /----------\
       / Integration \     ~15% — service boundaries, DB, external APIs
      /----------------\
     /      Unit        \   ~80% — every public function, every branch
    /--------------------\
```

**Rules:**
- Unit tests: happy path + error path + edge cases
- Integration tests: API contracts, database queries
- E2E tests: production path verification, max 10 per service
- Tests must be deterministic — no sleep-based waits, no order-dependent tests

### Error Handling

1. **Fail fast** — validate inputs at system boundary, return immediately on invalid
2. **No empty catch blocks** — handle, log-and-rethrow, or explicitly justify
3. **Two audiences for errors:**
   - Client: safe, actionable message ("Invalid email format")
   - Logs: detailed with context (`validation failed: email='<>' request_id=abc123`)
4. **Retry with backoff** — exponential backoff + jitter for external calls, max 3 retries

### Structured Logging (Application Code)

Adapt to the project's stack. These are principles, not a rigid schema — apply what makes sense for the type of software being built (web API, CLI tool, library, mobile app, embedded system, etc.).

**Minimum fields per log entry:**
- `timestamp` (ISO 8601 UTC)
- `level` (debug, info, warn, error)
- `message` (human-readable, one sentence)

**Additional fields when applicable:**
- `request_id` or `correlation_id` (for services handling requests)
- `component` (for multi-module systems)
- `user_id` (for multi-user systems — use opaque ID, never PII)
- `duration_ms` (for operations where performance matters)

**Log levels:**
- `error`: something failed that needs attention
- `warn`: unexpected but handled gracefully
- `info`: significant events worth tracking
- `debug`: diagnostic detail (disabled in production)

**Never log:** passwords, tokens, API keys, session IDs, PII, credit cards, full request bodies with sensitive fields

**Log security events when the application handles auth/data:**
- Authentication failures
- Authorization denials
- Input validation failures (field name, not the value if sensitive)
- Rate limit triggers
- Configuration changes
- Access to sensitive resources

### Workflow Observability (AI Pipeline)

The AI development pipeline itself must have full observability. This is what makes it auditable and improvable over time.

**Log file:** `.factory/workflow.log` (JSONL — one JSON per line)
**Session state:** `.factory/session.json` (metrics for current run)

Every tool invocation by the orchestrator logs:
```json
{"ts":"ISO8601","phase":"plan|implement|review","tool":"claude_code|codex|gh",
 "status":"ok|error|retry","duration_ms":N,
 "decision":"why this action was taken","detail":"what happened"}
```

Token and cost fields are optional — include them when the provider exposes that data.

**Always tracked (required):**
- Duration per phase (where is the bottleneck?)
- Retry count and reasons (what keeps failing?)
- Review cycles per PR (are plans getting better over time?)
- Security findings by severity (is the implementer learning?)
- Scope violations (are file boundaries being respected?)
- Every decision and its rationale (why was this approach chosen?)

**Tracked when available (optional):**
- Token usage by phase (planning vs implementation vs review)
- Estimated cost per run

**Why:** Without observability, you cannot identify bottleneck phases, detect patterns in review findings, optimize the pipeline, or audit decisions. The development process must be as observable as the software it produces.

### Performance Standards

Define measurable targets at planning time. Examples by project type:

| Project Type | Metric | Target |
|-------------|--------|--------|
| Web API | Response p99 latency | < 500ms |
| Web API | DB query p95 | < 50ms |
| CLI tool | Startup time | < 2s |
| Library | Zero-cost abstractions | No runtime overhead vs hand-written |
| Mobile app | Frame render time | < 16ms (60fps) |
| Any | Memory growth under load | Bounded (no leaks) |

**Universal rules:**
- No N+1 queries (when using databases)
- No unbounded loops or recursion without depth limits
- No unbounded list/collection operations — always paginate or limit
- Connection/resource pools must be bounded and leak-tested
- Profile before optimizing — measure, don't guess

### API Design (when building APIs)

Apply when the project exposes APIs (REST, GraphQL, gRPC, etc.):

**REST conventions:**
- Nouns for resources (`/users`, not `/getUsers`)
- HTTP methods: GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove)
- Status codes: 200, 201, 204, 400, 401, 403, 404, 409, 422, 429, 500
- Consistent error format:
  ```json
  {"error": {"code": "VALIDATION_ERROR", "message": "...", "details": [...]}}
  ```
- Version in URL: `/api/v1/resource`
- Paginate all list endpoints

---

## Contract-Compiled Pipeline

Every phase output is validated against JSON schemas before the pipeline advances. Invalid outputs block progression.

| Phase | Schema | Validated By |
|-------|--------|-------------|
| Strategic Plan | `schemas/strategic-plan.schema.json` | OpenClaw after Claude Code /plan |
| Tactical Plan | `schemas/tactical-plan.schema.json` | OpenClaw after Claude Code /plan |
| Code Review | `schemas/review-output.schema.json` | OpenClaw after Claude Code /review |
| Completion | `schemas/scorecard.schema.json` | OpenClaw at workflow end |
| Lesson | `schemas/lesson.schema.json` | OpenClaw after lesson extraction |

**Rule:** If schema validation fails, retry the phase once with the error message. If retry fails, escalate to user.

**Business rules beyond schema:**
- No two tasks in the same wave may share files_in_scope (disjoint ownership)
- Dependencies between tasks must reference existing task IDs
- Wave N+1 tasks can only depend on wave N or earlier

---

## Learning Loop

Review findings, retries, and failures generate structured lessons that feed future planning.

### How It Works

1. After every code review with findings, extract lessons to `.factory/lessons/` as JSON matching `schemas/lesson.schema.json`
2. Before every planning phase, load relevant lessons and pass them to the planner
3. The planner adds `preventive_controls` to acceptance criteria based on lessons
4. Over time, the pipeline generates fewer findings because the planner has learned to prevent them

### Lesson Structure

Each lesson captures:
- **pattern**: The recurring issue observed (e.g., "missing rate limiting on public endpoints")
- **root_cause**: Why this keeps happening
- **preventive_rule**: Concrete rule to prevent recurrence
- **scope**: this-project | same-stack | universal
- **confidence**: high | medium | low
- **times_seen**: Incremented on each recurrence (deduplication)

### Governance

- Lessons are append-only — never deleted, only superseded
- Duplicate patterns are deduplicated (increment `times_seen`, update `last_seen`)
- Lessons with `confidence: low` and `times_seen: 1` are suggestions, not rules
- Lessons with `confidence: high` or `times_seen >= 3` become mandatory planning constraints
- Cross-project lessons (scope: universal) can be exported to heuristics packs

---

## Architectural Decision Records (ADRs)

For medium+ risk changes that involve architectural choices, the strategic plan must include `architectural_decisions[]`. ADRs are persisted to `adr/` after plan approval.

### When ADRs Are Required

- Any change that introduces a new service, database, queue, or external dependency
- Any change that modifies authentication, authorization, or encryption architecture
- Any change where the planner considered 2+ viable alternatives
- Any change classified as `risky-infra`

### ADR Format

See `templates/ADR_TEMPLATE.md`. Key fields:
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Rationale**: Why this option over others
- **Consequences**: Positive, negative, and risks
- **Decision confidence**: high | medium | low

ADRs are machine-readable when included in the strategic plan JSON (`architectural_decisions[]` array).

---

## Heuristics Packs

Domain-specific knowledge packs that augment planning and review for specific project types.

### What a Pack Contains

- **lessons**: Reusable lessons from the domain
- **planning_rules**: Additional constraints the planner must follow (trigger → rule)
- **review_checks**: Additional review checklist items with severity
- **metric_overrides**: Domain-specific performance targets

### How to Use

1. Place pack JSON in `packs/` directory (must validate against `schemas/heuristics-pack.schema.json`)
2. List active packs in `workflow.yaml` config
3. Pack rules are automatically loaded before planning and review phases

### Available Packs

| Pack | Domain | Key Rules |
|------|--------|----------|
| `pack-saas-api` | SaaS backend APIs | Rate limiting, multi-tenancy, billing safety, API design |

Create custom packs by following the schema. Export project lessons with `scope: universal` to seed new packs.

---

## Scope Discipline

### File Ownership Rules

1. **One owner per file** — no two tasks in the same wave modify the same file
2. **Explicit scope** — every task lists files it CAN and CANNOT modify
3. **Scope violations block merge** — if a PR modifies out-of-scope files, it fails review
4. **Scope changes require re-planning** — if you need to modify a file not in scope, go back to planning

### Context Engineering

- **Fresh context per tool invocation** — do not carry conversation history between phases
- **Load only what the task needs:**
  1. AGENTS.md (methodology)
  2. Active lessons from `.factory/lessons/` (relevant to current task)
  3. Active heuristics pack rules (if packs configured)
  4. Relevant source files (from task scope)
  5. Task specification (from issue)
- **Do not load:** node_modules, dist, build, .git, unrelated source files
- **Deterministic checks first** — run cheap regex/script checks before invoking LLM

---

## Common Pitfalls

| # | Pitfall | Rule |
|---|---------|------|
| 1 | Code without an issue | Every task starts with a GitHub Issue |
| 2 | Planning without reading code | ALWAYS read codebase before planning |
| 3 | Two agents editing same file | One owner per file — disjoint scope |
| 4 | "Done" without evidence | Build + test output in every PR |
| 5 | Testing only on localhost | Validate on production path |
| 6 | Pushing through failing plan | STOP and re-plan |
| 7 | Scope creep during implementation | Only modify files in scope |
| 8 | Rubber-stamping security review | Each checklist item verified against actual diff |
| 9 | Hardcoded secrets | Environment variables or vault only |
| 10 | Empty catch blocks | Handle, log, or justify — never silently swallow |
