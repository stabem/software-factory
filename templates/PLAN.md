# PLAN.md — Software Factory Planning Contract

> Use this template before implementation for any non-trivial change.

## Meta
- Change class: `hotfix | feature | refactor | risky-infra`
- Owner:
- Date:
- Related issue/PR:

## 1) Problem statement
- What is broken / needed?
- Evidence (logs, DB query, user reports, metrics):

## 2) Root cause
- Confirmed root cause:
- Why previous behavior failed:

## 3) Scope
### In scope
- [ ]
- [ ]

### Out of scope
- [ ]
- [ ]

## 4) Definition of Ready (DoR)
- [ ] Problem has objective evidence
- [ ] Root cause is identified (not symptom)
- [ ] In-scope / out-of-scope is explicit
- [ ] Validation commands are defined
- [ ] Rollback command/path is defined
- [ ] NFR targets are declared (latency/cost/security/observability) when relevant

## 5) Solution spec
- Files to change:
- Behavioral contract after change:
- Compatibility notes:

## 6) Task packets (for agents)

### Packet A
- Outcome:
- Scope:
- Out of scope:
- Validation:
- Rollback note:

### Packet B
- Outcome:
- Scope:
- Out of scope:
- Validation:
- Rollback note:

## 7) Verification commands
```bash
# build

# tests

# production-path verification
```

## 8) Rollback
```bash
# exact rollback command(s)
```

## 9) Definition of Done (DoD)
- [ ] Code implemented in scoped files only
- [ ] Build/tests pass with evidence
- [ ] PR opened with root cause + validation + rollback
- [ ] Required checks/reviews are green
- [ ] Merged to default branch
- [ ] Deploy validation recorded (when applicable)

## 10) Risks and mitigations
- Risk:
- Mitigation:
