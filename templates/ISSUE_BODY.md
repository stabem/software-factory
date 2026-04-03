## 1. Classification

| Field | Value |
|-------|-------|
| **Change Class** | `{change_class}` |
| **Priority** | `{priority}` |
| **Security Risk** | `{security_risk_level}` |
| **Parent Feature** | #{parent_issue_number} |
| **Wave** | {wave} |
| **Dependencies** | {dependencies} |
| **Trigger Source** | {trigger_source} |

## 2. Problem Statement

{problem_statement}

## 3. Requirements & Acceptance Criteria

### Functional Requirements

{foreach criterion in acceptance_criteria}
- [ ] {criterion}
{endforeach}

### Preventive Controls (from lessons learned)

{foreach control in preventive_controls}
- [ ] {control.rule} (source: {control.lesson_id})
{endforeach}

### Definition of Done

- [ ] All acceptance criteria implemented and tested
- [ ] Build passes with zero errors
- [ ] Tests cover happy path, error path, and edge cases
- [ ] No regressions in existing test suite
- [ ] Security checks completed
- [ ] PR opened with full template completed

## 4. Technical Scope

### Files In Scope

{foreach file in files_in_scope}
- `{file}`
{endforeach}

### Files Out of Scope (Do NOT modify)

{foreach file in files_out_of_scope}
- `{file}`
{endforeach}

## 5. Security Assessment

**Risk Level:** {security_risk_level}

{security_notes}

### Security Checklist

- [ ] No hardcoded credentials, tokens, or secrets
- [ ] Authentication checks not bypassed
- [ ] All user inputs validated and sanitized
- [ ] No SQL/XSS/command injection vectors
- [ ] PII/sensitive data not logged
- [ ] No new dependencies with known CVEs

## 6. Architectural Decisions

{if architectural_decisions}
{foreach adr in architectural_decisions}
### ADR: {adr.title}
- **Decision:** {adr.decision}
- **Rationale:** {adr.rationale}
- **Confidence:** {adr.decision_confidence}
{endforeach}
{else}
No architectural decisions required for this task.
{endif}

## 7. Validation Commands

```bash
# Build
{validation_commands.build}

# Test
{validation_commands.test}
```

## 8. Rollback Strategy

```bash
{rollback}
```

## 9. Incident Context

{if trigger_source == "incident"}
- **Error Fingerprint:** {incident_context.error_fingerprint}
- **Stack Trace:** {incident_context.stack_trace}
- **Affected Service:** {incident_context.affected_service}
- **Environment:** {incident_context.environment}
- **First Seen:** {incident_context.first_seen}
- **Last Seen:** {incident_context.last_seen}
- **Incident URL:** {incident_context.incident_url}
{else}
N/A — not triggered by incident.
{endif}
