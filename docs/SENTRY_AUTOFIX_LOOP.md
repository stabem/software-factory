# Sentry Autofix Loop

Use this loop when production incidents in Sentry should be turned into tracked engineering work instead of ad-hoc firefighting.

## Goal

Convert a real production incident into a disciplined Software Factory execution flow:

**Sentry incident -> Issue -> scoped implementation -> PR -> Claude review -> merge -> verify**

The point is not blind auto-patching. The point is fast, auditable remediation with clear ownership and rollback.

## When to use it

Use this pattern when:
- a Sentry incident is actionable
- the failure affects a production user path, API, worker, webhook, or background job
- the incident is specific enough to map to a subsystem or stack trace
- you want the agent to keep working the loop until there is a merged fix and post-merge verification

Do **not** use it for:
- noisy low-signal incidents with no reproducible path
- incidents already covered by an open issue/PR for the same fingerprint unless continuing that exact thread
- secrets handling that would require committing credentials into a public repo

## The loop

### 1) Investigate
Before creating code changes:
- identify the incident title / fingerprint / environment / first-seen / last-seen
- confirm it is still relevant
- identify the likely endpoint, subsystem, worker, or file set
- check whether there is already an open issue or PR for the same incident family

### 2) Create or update the issue
Every incident should map to one canonical execution issue.

Required issue structure:

```md
## Outcome
[clear testable expected result]

## Incident
- source: Sentry
- environment: production
- fingerprint: [...]
- first seen: ...
- last seen: ...
- latest event: ...

## In Scope
- exact files / systems allowed

## Out of Scope
- unrelated refactors
- unrelated product changes

## Validation
- exact commands
- exact runtime checks

## Deliverables
- changed files
- PR link
- evidence
- rollback note
```

## 3) Implement on a scoped branch
Rules:
- branch name pattern: `fix/sentry-<short-slug>`
- keep the fix tightly scoped to the incident
- avoid mixing unrelated cleanup into the same PR
- prefer the smallest root-cause fix that cleanly removes the incident

## 4) Validate locally
Run the narrowest commands that prove the fix.

Examples:
- typecheck / compile
- focused unit or integration tests
- endpoint-specific smoke test
- post-merge production-path verification when applicable

If deterministic validation is impossible, explicitly document the gap.

## 5) Open a PR
Use a PR body that passes the factory gate.

Minimum required sections:
- `## Summary`
- `Change class: hotfix|feature|refactor|risky-infra`
- `## Root cause`
- `## Validation`
- `## Rollback`

## 6) Run Claude review on the real PR diff
Claude review is a quality gate.

Required loop:
1. open PR
2. run Claude review against the real GitHub diff
3. fix blocking findings in the same PR
4. rerun Claude review
5. merge only when blockers are gone

## 7) Merge and verify
After merge:
- monitor deploy/check pipeline
- verify the affected runtime path or endpoint
- check whether the Sentry symptom stops reproducing
- update the issue/PR with evidence and residual risk

## Operational rules

### Secrets
Public repos must never receive:
- Sentry auth tokens
- webhook secrets
- internal URLs that should stay private
- copied production credentials

Keep secrets in env / local ignored files / deployment secrets.

### Duplicate suppression
If the same fingerprint is already tracked by an open issue or active PR:
- update the existing thread
- do not create a fresh issue every hour

### Safe automation posture
Autonomous remediation is acceptable only when:
- issue creation is deterministic
- PRs remain review-gated
- merge still respects CI + Claude review
- post-merge verification is explicit

## Template
A public-safe hourly cron prompt template lives at:

- `templates/automation/sentry-hourly-autofix.prompt.md`

Use that file as the source of truth for repo-specific scheduled Sentry remediation jobs.
