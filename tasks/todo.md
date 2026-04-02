# Software Factory — Active Tasks

## Phase: Verification

### Current Sprint
- [x] Add methodology doc for the Sentry incident autofix loop
- [x] Add a public-safe hourly cron prompt template for Sentry-driven remediation
- [x] Reference the Sentry autofix loop from the main README
- [ ] Open PR and run review on the real diff

### Blocked
- [ ] None

### Review
- Added `docs/SENTRY_AUTOFIX_LOOP.md` with the issue -> PR -> Claude review -> merge -> verify flow.
- Added `templates/automation/sentry-hourly-autofix.prompt.md` as a public-safe template with no confidential values.
- Linked the new flow from `README.md`.
