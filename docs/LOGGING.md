# Logging Standard

> Enterprise logging specification for the LLM-Guided Software Architecture framework.
> Covers two domains: **Pipeline Logs** (what the AI did) and **Application Logs** (what the built software does).

---

## 1. Pipeline Logs (AI Workflow Observability)

Every action the orchestrator takes during a workflow run is logged to `.factory/workflow.log` as JSONL (one JSON object per line).

### 1.1 Log Entry Schema

```json
{
  "ts":          "2026-04-03T10:02:00Z",
  "sid":         "a1b2c3d4-e5f6-7890",
  "level":       "info",
  "phase":       "strategic_plan",
  "action":      "invoke_claude",
  "status":      "ok",
  "tool":        "claude_code",
  "duration_ms": 110000,
  "detail":      "Strategic plan generated: 3 tasks across 2 waves",
  "decision":    "Split by file ownership for parallel execution",
  "refs": {
    "issue":  42,
    "pr":     null,
    "branch": null,
    "commit": null
  },
  "error":       null,
  "tokens":      { "input": 8500, "output": 6200 },
  "cost_usd":    null
}
```

### 1.2 Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | ISO 8601 UTC | yes | When the event occurred |
| `sid` | string | yes | Session ID — links all entries from the same workflow run |
| `level` | enum | yes | `debug`, `info`, `warn`, `error` |
| `phase` | string | yes | Workflow phase: `intake`, `strategic_plan`, `issue_creation`, `tactical_plan`, `implementation`, `code_review`, `merge`, `completion` |
| `action` | string | yes | What happened (see Action Types below) |
| `status` | enum | yes | `ok`, `error`, `retry`, `skip` |
| `tool` | string | no | Which tool executed: `claude_code`, `codex`, `gh`, `preflight`, `schema_validator` |
| `duration_ms` | integer | no | Wall-clock time for this action |
| `detail` | string | yes | Human-readable description of what happened |
| `decision` | string | no | Rationale when the orchestrator made a non-trivial choice |
| `refs.issue` | integer | no | GitHub issue number related to this action |
| `refs.pr` | integer | no | GitHub PR number related to this action |
| `refs.branch` | string | no | Git branch name |
| `refs.commit` | string | no | Git commit SHA |
| `error` | string | no | Error message when `status=error` |
| `tokens.input` | integer | no | Input tokens consumed (when provider exposes) |
| `tokens.output` | integer | no | Output tokens generated (when provider exposes) |
| `cost_usd` | number | no | Estimated cost (when provider exposes) |

### 1.3 Action Types

| Action | Level | When |
|--------|-------|------|
| `session_init` | info | Workflow session started |
| `phase_start` | info | Phase begins execution |
| `phase_end` | info | Phase completes (ok or error) |
| `invoke_claude` | info | Claude Code CLI invoked (/plan or /review) |
| `invoke_codex` | info | Codex invoked for implementation |
| `schema_validate` | info | Schema validation ran on phase output |
| `decision` | info | Orchestrator made a non-trivial choice |
| `lesson_extracted` | info | Lesson written to `.factory/lessons/` |
| `lessons_consolidated` | info | Lessons deduplicated/upgraded at completion |
| `scorecard_generated` | info | Scorecard written to `.factory/scorecards/` |
| `adr_persisted` | info | Architectural Decision Record saved to `adr/` |
| `pack_loaded` | info | Heuristics pack loaded and rules applied |
| `inline_issue_created` | info | Issue created inline (hotfix/refactor path) |
| `post_merge_verify` | info | Post-merge verification executed |
| `error` | error | An operation failed |
| `retry` | warn | Retrying a failed operation |
| `escalation` | warn | Human intervention requested |

### 1.4 Level Guidelines (Pipeline)

| Level | When to Use | Example |
|-------|-------------|---------|
| `error` | Operation failed, pipeline blocked | Schema validation failed after retry |
| `warn` | Unexpected but handled | Retry triggered, escalation needed |
| `info` | Normal pipeline operations | Phase started, tool invoked, plan generated |
| `debug` | Diagnostic detail (verbose mode only) | File watcher detected change, SSE broadcast |

### 1.5 Session State File

`.factory/session.json` tracks cumulative metrics for the current run:

```json
{
  "session_id": "a1b2c3d4-e5f6-7890",
  "feature": "Add Payment Processing",
  "started_at": "2026-04-03T12:00:00Z",
  "trigger_source": "user",
  "current_phase": "implementation",
  "phases_completed": ["intake", "strategic_plan", "issue_creation", "tactical_plan"],
  "tasks": { "total": 3, "completed": 1, "failed": 0, "blocked": 0 },
  "metrics": {
    "total_duration_ms": 600000,
    "planning_ms": 120000,
    "implementation_ms": 0,
    "review_ms": 0,
    "retries": 1,
    "review_cycles": 0,
    "auto_repairs": 0,
    "scope_violations": 0,
    "lessons_generated": 0
  },
  "decisions_log": [
    {
      "ts": "2026-04-03T12:01:00Z",
      "decision": "Use Stripe SDK over raw API",
      "rationale": "Better type safety and webhook handling",
      "phase": "strategic_plan"
    }
  ]
}
```

Updated after every phase transition.

---

## 2. Application Logs (Built Software)

When the pipeline builds application code, it must follow these logging standards. The planner includes these as requirements in acceptance criteria. The reviewer verifies compliance.

### 2.1 Log Entry Format

Adapt to the project's stack and language. The structure matters more than exact field names.

**Minimum fields (all project types):**

```json
{
  "ts": "2026-04-03T14:30:00.123Z",
  "level": "info",
  "msg": "User registered successfully",
  "component": "auth"
}
```

**Extended fields (services handling requests):**

```json
{
  "ts": "2026-04-03T14:30:00.123Z",
  "level": "error",
  "msg": "Payment charge failed",
  "component": "billing",
  "request_id": "req-abc-123",
  "user_id": "usr-opaque-456",
  "duration_ms": 2340,
  "error_code": "STRIPE_CARD_DECLINED",
  "metadata": {
    "amount_cents": 5000,
    "currency": "usd",
    "idempotency_key": "idem-789"
  }
}
```

### 2.2 Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `ts` | yes | ISO 8601 UTC with milliseconds |
| `level` | yes | `debug`, `info`, `warn`, `error` |
| `msg` | yes | Human-readable, one sentence, present tense |
| `component` | yes | Module, service, or subsystem name |
| `request_id` | when applicable | Correlation ID for request tracing (propagated across services) |
| `user_id` | when applicable | Opaque user identifier (never email, name, or PII) |
| `duration_ms` | when applicable | Operation wall-clock time |
| `error_code` | on errors | Machine-readable error classification |
| `metadata` | when applicable | Structured context (no sensitive data) |

### 2.3 Level Guidelines (Application)

| Level | Trigger | Action Required | Example |
|-------|---------|-----------------|---------|
| `error` | Operation failed, user impacted or data at risk | Alert, investigate | `Payment charge failed`, `Database connection lost` |
| `warn` | Unexpected condition, handled gracefully | Review periodically | `Rate limit approached (80%)`, `Deprecated API called` |
| `info` | Significant business event | None — audit trail | `User registered`, `Order completed`, `Deploy finished` |
| `debug` | Diagnostic detail | None — disabled in prod | `Cache miss for key X`, `SQL query took 45ms` |

### 2.4 What to Log (Security Events)

These events MUST be logged at `info` or `warn` level for audit trail:

| Event | Level | Required Fields |
|-------|-------|-----------------|
| Authentication failure | warn | `user_id` (if known), `ip`, `user_agent`, `reason` |
| Authentication success | info | `user_id`, `method` (password, oauth, mfa) |
| Authorization denial | warn | `user_id`, `resource`, `action`, `required_role` |
| Input validation failure | warn | `field`, `rule_violated` (never the invalid value if PII) |
| Rate limit triggered | warn | `client_id` or `ip`, `endpoint`, `limit`, `window` |
| Sensitive data accessed | info | `user_id`, `resource_type`, `record_count` |
| Configuration changed | info | `actor`, `setting`, `old_value`, `new_value` |
| Permission changed | info | `actor`, `target_user`, `role_before`, `role_after` |
| Account locked/unlocked | warn | `user_id`, `reason`, `actor` |
| Password changed/reset | info | `user_id`, `method` (self, admin, reset-link) |
| API key created/revoked | info | `actor`, `key_prefix` (first 4 chars only) |
| Data export requested | info | `user_id`, `export_type`, `record_count` |

### 2.5 What NEVER to Log

| Forbidden | Why | What to Log Instead |
|-----------|-----|-------------------|
| Passwords (plain or hashed) | Credential exposure | `"msg": "password changed"` |
| API keys / tokens / secrets | Credential exposure | `"key_prefix": "sk-a1"` (first 4 chars) |
| Session IDs / JWTs | Session hijacking | `"session_active": true` |
| Credit card numbers | PCI DSS violation | `"card_last4": "4242"` |
| Full SSN / tax IDs | PII exposure | `"ssn_present": true` |
| Email addresses | GDPR / privacy | `"user_id": "usr-opaque-456"` |
| Phone numbers | PII exposure | `"phone_verified": true` |
| Physical addresses | PII exposure | `"country": "US"` |
| Full request/response bodies | May contain any of the above | Log selected safe fields |
| Stack traces at info/warn | Noise, internal exposure | Stack traces only at `error` level |
| File paths with usernames | Internal architecture exposure | Use relative paths |

### 2.6 Log Format by Project Type

| Project Type | Format | Transport | Retention |
|-------------|--------|-----------|-----------|
| Web API / Backend | JSON (structured) | stdout → log aggregator | 30-90 days |
| CLI tool | Human-readable, JSON with `--verbose` | stderr | Session only |
| Library | No direct logging — accept a logger interface | Caller decides | Caller decides |
| Mobile app | Structured, batched upload | SDK → analytics backend | Per privacy policy |
| Worker / Background job | JSON (same as API) | stdout → log aggregator | 30-90 days |
| Infrastructure / IaC | JSON with `resource_id` and `operation` | CloudWatch / equivalent | 90+ days |

### 2.7 Observability Beyond Logs

Logging is one pillar. When applicable, the planner should also require:

| Pillar | What | Example |
|--------|------|---------|
| **Metrics** | Counters, gauges, histograms | `http_requests_total`, `payment_amount_sum`, `queue_depth` |
| **Tracing** | Distributed request traces | W3C Trace Context propagation across services |
| **Health checks** | Readiness and liveness probes | `GET /healthz` → 200 with service status |
| **Alerting** | Threshold-based notifications | Error rate > 1% for 5min → page oncall |

---

## 3. Integration with Pipeline

### How the Planner Uses This

When `CLAUDE_PLAN.md` generates acceptance criteria, it must include logging requirements:

- "Every new endpoint MUST log request completion at `info` level with `request_id`, `duration_ms`, and `status_code`"
- "Authentication failures MUST be logged at `warn` level with `ip` and `user_agent`"
- "No PII in logs — use opaque `user_id`, never email or name"

### How the Reviewer Checks This

When `CLAUDE_REVIEW.md` reviews code, it verifies:

- [ ] New endpoints have structured logging
- [ ] Error paths log at `error` level with `error_code`
- [ ] Security events from section 2.4 are logged
- [ ] No forbidden data from section 2.5 appears in log statements
- [ ] Log level is appropriate (not `info` for debug detail, not `debug` for errors)

### How the Dashboard Shows This

The dashboard's Timeline and Decisions views render pipeline logs directly from `.factory/workflow.log`. The log format defined in section 1 is what the dashboard API parses and displays.
