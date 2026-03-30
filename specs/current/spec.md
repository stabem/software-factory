# SPEC-20260330-sdd-lean-hardening

## Problem
Review feedback highlighted that the lean SDD gate can pass with low-value specs (headings only) and that local change detection/rules were not explicit enough.

## Scope
### In Scope
- Harden `scripts/check-sdd-gate.sh` to enforce meaningful section content
- Include staged + unstaged + untracked files in local mode
- Improve failure hints for missing spec file
- Clarify non-trivial criteria in README

### Out of Scope
- Full schema validation for specs
- Additional CI workflows
- ADR/test-plan requirements in lean mode

## Acceptance Criteria
- [x] Gate fails if required sections exist but are empty
- [x] Gate fails when spec is identical to template or still has placeholders
- [x] Local mode captures staged, unstaged, and untracked changes
- [x] README clarifies non-trivial threshold and copy flow

## Validation
```bash
bash scripts/check-sdd-gate.sh
```

## Rollback
```bash
git restore README.md scripts/check-sdd-gate.sh specs/current/spec.md
```
