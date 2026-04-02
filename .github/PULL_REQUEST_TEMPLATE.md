## Meta

| Field | Value |
|-------|-------|
| **Issue** | Closes #<!-- issue number --> |
| **Change Class** | `hotfix` / `feature` / `refactor` / `risky-infra` |
| **Risk Level** | `low` / `medium` / `high` / `critical` |
| **Plan Reference** | <!-- link to tasks/plan.md or plan commit --> |

---

## 1. Summary

<!-- 2-3 sentences: WHAT changed and WHY. Link to the issue for full context. -->

---

## 2. Root Cause

<!-- What was the underlying problem? Why did the previous behavior fail?
     For features: what gap existed and why does this solution fill it? -->

---

## 3. Changes Made

<!-- Describe the changes at a technical level. Map each change to a requirement from the issue. -->

| File | Change | Requirement |
|------|--------|-------------|
| <!-- path --> | <!-- what changed --> | <!-- FR-1, NFR-2, etc. --> |

---

## 4. Scope Compliance

<!-- Verify changes match the approved plan/issue scope. -->

- [ ] All modified files are listed in the issue's "Files In Scope"
- [ ] No files outside scope were modified
- [ ] No scope expansion occurred without re-planning
- [ ] Change class matches the declared class in the issue

**Files modified:** <!-- list all changed files -->

**Files that should NOT have been modified (out-of-scope check):**
<!-- Confirm none of the out-of-scope files from the issue were touched -->

---

## 5. Validation Evidence

<!-- Paste actual command outputs. No evidence = PR not ready for review. -->

### Build
```
<!-- paste build output -->
```

### Tests
```
<!-- paste test output with pass/fail counts -->
```

### Production Path Verification
```
<!-- paste E2E or production-path test output -->
<!-- localhost-only testing is NOT sufficient -->
```

### Regression Check
```
<!-- paste full test suite output confirming no regressions -->
```

- [ ] Build passes with zero errors
- [ ] All new tests pass
- [ ] All existing tests pass (no regressions)
- [ ] Production path verified (not just localhost)
- [ ] Edge cases tested per issue's Test Coverage Plan

---

## 6. Security Review

<!-- EVERY PR must complete this section. Mark N/A with justification. -->

### 6.1 Authentication & Authorization
- [ ] No hardcoded credentials, tokens, API keys, or secrets in code
- [ ] No `.env` files or secret files committed
- [ ] Authentication checks are not bypassed or weakened
- [ ] Authorization (RBAC/ABAC) enforced at the correct layer
- [ ] Session management is not degraded
- [ ] Token handling follows secure patterns (expiry, rotation, revocation)

### 6.2 Input Validation & Injection Prevention
- [ ] All user inputs validated and sanitized at system boundary
- [ ] No SQL injection vectors (parameterized queries used)
- [ ] No XSS vectors (output encoding applied, CSP headers maintained)
- [ ] No command injection vectors (no shell exec with user input)
- [ ] No path traversal vulnerabilities
- [ ] No SSRF vectors (URL validation on external requests)
- [ ] No prototype pollution or deserialization attacks

### 6.3 Data Protection
- [ ] PII / sensitive data not logged or exposed in error messages
- [ ] Data at rest encryption maintained
- [ ] Data in transit uses TLS/HTTPS exclusively
- [ ] No sensitive data in URL query parameters
- [ ] GDPR / privacy requirements maintained (consent, right to delete)
- [ ] No unnecessary data collection or retention

### 6.4 Dependency Security
- [ ] No new dependencies with known CVEs (`npm audit` / `pip audit` / equivalent clean)
- [ ] Dependency versions are pinned (no floating ranges for critical deps)
- [ ] No unnecessary new dependencies added
- [ ] License compatibility verified for new dependencies

### 6.5 Infrastructure & Configuration
- [ ] No debug/development endpoints exposed in production
- [ ] No overly permissive IAM/RBAC policies
- [ ] Rate limiting maintained on public endpoints
- [ ] CORS policy not weakened
- [ ] Error messages don't leak internal architecture details

### 6.6 Threat Model Verification
<!-- For medium/high/critical risk PRs: confirm threat model from issue was addressed -->
- [ ] Threat vectors from issue's security assessment are mitigated
- [ ] No new attack surfaces introduced
- [ ] Security controls match or exceed the risk level

**Security review notes:**
<!-- Any security concerns, decisions, or exceptions. Justify any N/A items. -->

---

## 7. Performance Impact

- [ ] No N+1 queries introduced
- [ ] No unbounded loops or recursive calls
- [ ] No memory leaks (event listeners, unclosed connections)
- [ ] Database queries are indexed and optimized
- [ ] Caching behavior is correct (no stale reads, no cache stampede)
- [ ] Payload sizes are reasonable (no unbounded responses)
- [ ] Latency impact is within NFR targets from issue

**Performance notes:**
<!-- Benchmark results, before/after metrics, or "no measurable impact" with justification -->

---

## 8. Observability

- [ ] Errors are logged with sufficient context for debugging
- [ ] No sensitive data in logs
- [ ] Metrics/alerts are maintained or added per NFR requirements
- [ ] Health check endpoints are not affected
- [ ] Tracing/correlation IDs are propagated correctly

---

## 9. Rollback Plan

<!-- Copy from issue, confirm it's still valid after implementation. -->

```bash
# Exact rollback commands
```

- [ ] Rollback plan tested or verified as viable
- [ ] No destructive migrations that prevent rollback
- [ ] Rollback does not cause data loss
- [ ] Rollback procedure documented above with exact commands

---

## 10. Documentation & Knowledge

- [ ] Code is self-documenting (clear naming, no magic numbers)
- [ ] Complex logic has inline comments explaining "why" (not "what")
- [ ] API changes are reflected in API docs/schemas (if applicable)
- [ ] Breaking changes are documented in CHANGELOG or migration guide
- [ ] `tasks/lessons.md` updated if any surprises or corrections occurred

---

## 11. Reviewer Checklist

<!-- For reviewers: complete this section during review -->

### Correctness
- [ ] Logic matches the requirements from the linked issue
- [ ] Edge cases are handled
- [ ] Error handling is appropriate (not over-engineered, not missing)
- [ ] Concurrency / race conditions considered

### Code Quality
- [ ] Code follows project conventions
- [ ] No dead code, commented-out code, or TODO debris
- [ ] No unnecessary abstractions or premature optimization
- [ ] Changes are minimal and focused (no drive-by refactors)

### Completeness
- [ ] All acceptance criteria from the issue are met
- [ ] Test coverage is adequate for the change
- [ ] Validation evidence is present and convincing
- [ ] Security checklist is completed honestly (not rubber-stamped)

### Final Verdict
- [ ] **APPROVED** — All checks pass, evidence is sufficient
- [ ] **REQUEST CHANGES** — Issues found (see comments with severity tags)

---

## 12. Post-Merge Validation

<!-- Complete AFTER merge, before marking the issue as done. -->

- [ ] Deployed to target environment
- [ ] Smoke test passed in production
- [ ] Monitoring dashboards show no anomalies
- [ ] No error rate increase after deploy
- [ ] Issue closed with deploy evidence

---

> **Software Factory Governance:** This PR follows the [Issue-First Development](../AGENTS.md) methodology.
> Every PR must link to an issue. Every issue must follow the SDD template. No code without a plan.
