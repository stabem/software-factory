# Verification Model

Software Factory verifies outcomes, not just activity. A task is not complete because code exists or a build passes. A task is complete when the intended behavior is proven with evidence.

## Core Principle
**Task completion != Goal achievement**

## Verification Stack
Every meaningful change should be verified through this stack:

1. **Goal** — what outcome this phase or plan is trying to achieve.
2. **Observable Truths** — user-visible or system-visible conditions that must be true.
3. **Required Artifacts** — files, routes, schemas, scripts, or configs that must exist meaningfully.
4. **Critical Links** — the connections between artifacts that make the outcome real.
5. **Evidence Commands** — commands that prove behavior or structure.
6. **Human Checks** — what still requires human validation.

## Verification States
- **passed** — evidence supports the goal and no blocking gaps remain.
- **gaps_found** — one or more truths, artifacts, or links failed.
- **human_needed** — automated checks passed as far as possible, but human validation is still required.

## Verification Workflow
```text
plan -> execute -> summary -> validation -> verification -> repair -> re-verification
```

## What Each Layer Means

### 1. Goal
Example:
- "User can create and view orders"

### 2. Observable Truths
Example:
- user can submit the order form
- order persists in the database
- order appears on refresh
- invalid input produces a clear error

### 3. Required Artifacts
Example:
- order schema/model
- POST /orders endpoint
- GET /orders endpoint
- Orders page/component

### 4. Critical Links
Example:
- order form -> POST /orders
- GET /orders -> database query
- Orders page -> GET /orders

### 5. Evidence Commands
Example:
- `npm test -- orders`
- `curl -X POST ...`
- `npm run build`

### 6. Human Checks
Example:
- visual hierarchy is clear
- mobile layout is usable
- error message copy is understandable

## Artifact Expectations by Work Type

### Backend / API
Verify:
- routes exist
- persistence exists
- invalid input is handled
- auth/security constraints hold
- response shape matches contract

### Frontend / UI
Verify:
- intended path exists in UI
- data loads from real source
- interactions work
- empty and error states exist
- human validation captures UX-only judgment

### Data / ETL / Pipeline
Verify:
- source read works
- transforms are correct
- outputs are written where expected
- idempotency or dedupe behavior is explicit
- monitoring / error behavior is defined

### Infra / Config / Deploy
Verify:
- config is applied to the right environment
- deployment path actually uses new config
- health checks or smoke checks pass
- rollback path is explicit

## Gap Generation Rules
A gap must include:
- failing truth
- affected requirement(s)
- broken or missing artifact(s)
- broken link(s)
- concrete evidence of failure
- recommended repair scope

A good gap is actionable. It should help create a repair plan without re-investigating from zero.

## Repair Loop
When verification fails:
1. record the failed truth(s)
2. identify broken artifacts and links
3. create repair plan(s)
4. execute repair plan(s)
5. re-run validation and verification
6. only then mark the requirement or phase as satisfied

## QA / Guardian Role
Automated review can prove a lot, but not everything.

### Automated review is strong for:
- structure
- missing files
- failing tests
- unsafe patterns
- requirement coverage mismatches
- regression indicators

### Human review is still required for:
- product fit
- visual quality
- UX clarity
- nuanced behavior judgment
- rollout safety in ambiguous environments

## Anti-Patterns
- treating build success as proof of delivery
- checking only that files exist
- skipping critical link verification
- writing vague 'tested manually' statements with no evidence
- closing a task before re-verification after a repair
