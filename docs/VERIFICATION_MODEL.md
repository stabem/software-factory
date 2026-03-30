# Verification Model

Software Factory verifies outcomes, not just activity. A task is not complete because a file exists or a build passes. It is complete when the intended behavior is proven with evidence.

## Core Principle
**Task completion != Goal achievement**

## 6-Layer Verification Stack
1. **Goal** — what outcome this work is meant to achieve.
2. **Observable Truths** — what must be true from the user/system point of view.
3. **Required Artifacts** — what files/routes/scripts/configs must exist meaningfully.
4. **Critical Links** — what connections between artifacts must actually work.
5. **Evidence Commands** — commands that prove structure or behavior.
6. **Human Checks** — what still requires human judgment.

## Verification Outcomes
- `passed`
- `gaps_found`
- `human_needed`

## Repair Loop
```text
plan -> execute -> summary -> verify -> gap -> repair -> re-verify
```

## How This Fits the Current Factory Flow
- planning defines goal + validation commands
- execution produces factual evidence
- QA/review verifies behavior and residual risk
- failed verification creates a repair loop, not a premature ship decision

## Gap Rules
A gap should identify:
- the failing truth
- affected artifact(s)
- broken critical link(s), if any
- evidence of failure
- recommended repair scope

## Backend Example
- **Goal:** user can create an order
- **Observable truth:** POST creates persisted order
- **Required artifacts:** route, schema/model, test
- **Critical links:** route -> persistence layer
- **Evidence commands:** build, test, curl/postman smoke
- **Human checks:** error copy / product semantics if needed

## Frontend Example
- **Goal:** user can complete onboarding
- **Observable truth:** user sees next-step guidance after signup
- **Required artifacts:** page/component/state wiring
- **Critical links:** UI -> API/session state
- **Evidence commands:** build, UI test, smoke test
- **Human checks:** clarity, hierarchy, UX quality

## Infra Example
- **Goal:** staged rollout is safe
- **Observable truth:** deployment succeeds without breaking health checks
- **Required artifacts:** workflow/config/checks
- **Critical links:** config -> runtime -> health probe
- **Evidence commands:** workflow logs, health checks, production-path validation
- **Human checks:** rollout judgment, incident communication
