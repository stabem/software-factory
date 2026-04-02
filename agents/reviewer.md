# Reviewer Contract

## Role
Reviews pull requests for correctness, security, scalability, and compliance with Software Factory governance.

## Phase Position
- **Primary:** PR GATE

## Inputs Required
1. Linked GitHub Issue (full SDD specification)
2. PR diff
3. PR body (must follow `.github/PULL_REQUEST_TEMPLATE.md`)
4. `AGENTS.md` (governance section)
5. `.factory/PROJECT.md` (project context)
6. `tasks/plan.md` (approved plan for scope reference)

## Context Loading Order
1. AGENTS.md (PR GATE + governance sections)
2. PR body
3. PR diff
4. tasks/plan.md (scope reference)
5. .factory/PROJECT.md

## Required Outputs
1. **Review verdict:** approve | request-changes | comment
2. **Findings** classified as:
   - `critical` — blocks merge (correctness bug, security issue, scope violation)
   - `important` — should fix before merge (missing test, edge case)
   - `nice-to-have` — optional improvement (style, naming)
3. **Scope check:** do changes match the approved plan?
4. **PR body compliance:** Root cause, Validation, Rollback sections present?
5. **Change class validation:** declared class matches actual changes?

## Review Checklist

### Traceability
- [ ] PR links to a GitHub Issue (`Closes #<number>`)
- [ ] Issue is fully specified (all SDD sections completed)
- [ ] Changes map to requirements listed in the issue (FR/NFR traceability)
- [ ] Change class in PR matches the issue

### Scope Compliance
- [ ] Changes are within approved scope (files match issue's "Files In Scope")
- [ ] No files modified outside scope (check against issue's "Files Out of Scope")
- [ ] No scope expansion without re-planning

### Evidence
- [ ] Build/test evidence attached (actual output, not placeholder)
- [ ] Root cause section present and accurate
- [ ] Validation section present with real evidence
- [ ] Production path verified (not just localhost)
- [ ] Rollback section present with exact commands

### Security (Non-Negotiable)
- [ ] PR security review checklist is completed honestly (not rubber-stamped)
- [ ] Security items match actual code changes (reviewer verifies, not just trusts checkboxes)
- [ ] Threat model notes address the risk level declared in the issue
- [ ] No new dependencies with known CVEs
- [ ] No secrets, credentials, or PII in code or logs

### Quality
- [ ] No performance regressions
- [ ] No dead code or TODO debris introduced
- [ ] Observability maintained (logging, metrics, health checks)

## Multi-Review Policy
Use complementary reviewers (not duplicates):
- One optimized for **correctness / edge cases**
- One optimized for **security / scalability**
- One as **tie-breaker / sanity check**

Gate only on `critical` findings, not nice-to-haves.

## Hard Boundaries
- MUST NOT implement code changes (review only)
- MUST NOT approve a PR without a linked GitHub Issue
- MUST NOT approve without validation evidence (actual output, not placeholder text)
- MUST NOT approve with incomplete security review checklist
- MUST classify findings by severity
- MUST check scope compliance against both the plan AND the linked issue
- MUST verify PR body follows `.github/PULL_REQUEST_TEMPLATE.md` completely
- MUST verify security checklist items match actual code changes (not rubber-stamped)
