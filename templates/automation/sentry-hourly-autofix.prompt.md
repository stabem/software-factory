# Hourly Sentry Autofix Prompt Template

This template is safe to store in a **public repo**.
It contains no credentials and assumes secrets come from env / ignored files / deployment secrets.

## Inputs to customize per repo
- `REPO_DIR`: absolute local checkout path
- `GITHUB_REPO`: owner/repo
- `RUNTIME_LABEL`: short human label for updates
- `DEFAULT_VALIDATION_COMMANDS`: repo-specific validation commands

Expected secret names are repo/operator-defined, but common examples are:
- `SENTRY_AUTH_TOKEN`
- `SENTRY_ORG`
- `SENTRY_PROJECT`

---

Work in repo: `REPO_DIR`
GitHub repo: `GITHUB_REPO`
Runtime label: `RUNTIME_LABEL`

## Mission
Inspect Sentry for **new actionable production incidents** affecting this repo and run the Software Factory loop:

**incident -> issue -> scoped fix -> PR -> Claude review -> address findings -> merge -> verify**

## Credential policy
- Use only credentials already available through env / ignored local files / deployment secrets.
- Never commit secrets.
- If Sentry read credentials are unavailable, do not fabricate incidents.
- If direct Sentry access is unavailable, fall back to continuing existing open incident issues / PRs for this same loop.
- If neither direct Sentry access nor an existing tracked incident is available, reply exactly `NO_REPLY`.

## Noise control
Only act on incidents that are:
- environment = production
- level = error or fatal
- specific enough to map to a subsystem or endpoint
- not already covered by an open remediation PR for the same fingerprint

Ignore:
- stale duplicates already tracked
- low-signal noise with no actionable evidence
- incidents already handled by an open canonical issue/PR unless continuing that exact thread

## Workflow

### 1) Investigate
- identify fingerprint / title / event count / first-seen / last-seen
- identify likely endpoint(s), subsystem(s), and file set(s)
- check whether there is already an open GitHub issue or PR for the same incident family

### 2) Create or update issue
If no canonical issue exists, create one with this structure:

```md
## Outcome
[clear expected behavior after fix]

## Incident
- source: Sentry
- environment: production
- fingerprint: [...]
- first seen: ...
- last seen: ...
- latest event: ...

## In Scope
- exact files/systems allowed

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

### 3) Implement
- create branch `fix/sentry-<short-slug>`
- keep the change narrowly scoped to the incident
- prefer the smallest clean root-cause fix

### 4) Validate
Run the narrowest commands that prove the fix.

Default validation commands:

```bash
DEFAULT_VALIDATION_COMMANDS
```

### 5) Open PR
PR body must contain:
- `## Summary`
- `Change class: hotfix|feature|refactor|risky-infra`
- `## Root cause`
- `## Validation`
- `## Rollback`

### 6) Claude review gate
Run Claude review on the **real GitHub PR diff**.
If Claude reports blockers:
- fix them in the same PR
- rerun Claude review
- repeat until there are no blockers

### 7) Merge and verify
Merge only when:
- CI is green
- Claude review has no blockers

After merge:
- monitor the deploy/check pipeline
- verify the affected runtime path
- confirm the original error is not still reproducing

## Communication policy
- If there is nothing actionable, reply exactly `NO_REPLY`.
- If work starts, send concise updates only at meaningful milestones:
  - issue created or updated
  - PR opened
  - Claude found blockers
  - merge completed
  - post-merge verification failed or succeeded

## Hard rules
- Never commit secrets.
- Never skip the issue/PR/review loop.
- Never merge with blocking Claude findings.
- Never claim verification without concrete evidence.
