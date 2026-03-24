#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR=""
MODE="standard"
PROJECT_TYPE="greenfield"
CRITICAL="false"
WITH_SWARM="false"
FULL_DOCS="false"
FORCE="false"

usage() {
  cat <<'EOF'
Usage: bootstrap-factory.sh <target-dir> [options]

Bootstrap a repo with Software Factory structure and profile-aware defaults.

Options:
  --mode <fast|standard|factory>     Operating mode (default: standard)
  --project-type <greenfield|brownfield>
                                     Project type (default: greenfield)
  --critical                         Mark repo as critical (enables stricter defaults)
  --with-swarm                       Include swarm registry/monitor assets
  --full-docs                        Always install full methodology docs
  --force                            Overwrite existing target files when safe
  -h, --help                         Show this help

Examples:
  ./scripts/bootstrap-factory.sh . --mode standard
  ./scripts/bootstrap-factory.sh ../new-repo --mode factory --project-type brownfield --critical --with-swarm
EOF
}

require_value() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "$value" || "$value" == --* ]]; then
    echo "Error: $flag requires a value" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      require_value "$1" "${2:-}"
      MODE="$2"
      shift 2
      ;;
    --project-type)
      require_value "$1" "${2:-}"
      PROJECT_TYPE="$2"
      shift 2
      ;;
    --critical)
      CRITICAL="true"
      shift
      ;;
    --with-swarm)
      WITH_SWARM="true"
      shift
      ;;
    --full-docs)
      FULL_DOCS="true"
      shift
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  usage >&2
  exit 1
fi

case "$MODE" in
  fast|standard|factory) ;;
  *)
    echo "Invalid --mode: $MODE" >&2
    exit 1
    ;;
esac

case "$PROJECT_TYPE" in
  greenfield|brownfield) ;;
  *)
    echo "Invalid --project-type: $PROJECT_TYPE" >&2
    exit 1
    ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$(mkdir -p "$TARGET_DIR" && cd "$TARGET_DIR" && pwd)"

write_if_absent() {
  local path="$1"
  local content="$2"
  if [[ -f "$path" && "$FORCE" != "true" ]]; then
    echo "skip: $path already exists"
    return
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
  echo "write: $path"
}

copy_if_needed() {
  local src="$1"
  local dest="$2"
  if [[ -f "$dest" && "$FORCE" != "true" ]]; then
    echo "skip: $dest already exists"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "copy: $dest"
}

read_file() {
  cat "$1"
}

CONFIG_CONTENT=$(cat <<EOF
{
  "mode": "$MODE",
  "projectType": "$PROJECT_TYPE",
  "critical": $CRITICAL,
  "swarm": {
    "enabled": $WITH_SWARM,
    "maxAgents": $( [[ "$MODE" == "factory" ]] && echo 3 || echo 1 )
  },
  "verification": {
    "model": "goal-backward",
    "prRequired": true
  }
}
EOF
)

README_CONTENT=$(cat <<EOF
# $(basename "$TARGET_DIR")

Bootstrapped with **Software Factory**.

## Selected Profile
- **Mode:** $MODE
- **Project type:** $PROJECT_TYPE
- **Critical repo:** $CRITICAL
- **Swarm enabled:** $WITH_SWARM

## Next Steps
1. Review AGENTS.md
2. Fill tasks/todo.md with the first active plan
3. If brownfield, map the codebase before planning changes
4. Open work on a branch and follow PR-first delivery

## Workflow Defaults
- Verification model: goal-backward
- PR required: yes
- Use mode escalation when scope or risk increases
EOF
)

TASKS_TODO_CONTENT=$(cat <<'EOF'
# Project — Active Tasks

## Phase: Planning

### Current Sprint
- [ ] Bootstrap complete — review generated files and adjust project-specific defaults
- [ ] Add first real task plan

### Blocked
- [ ] None

### Review
- Mode selected and project bootstrapped.
EOF
)

TASKS_LESSONS_CONTENT=$(cat <<'EOF'
# Lessons Learned

Add lessons here as the project evolves.
EOF
)

PLAN_TEMPLATE_CONTENT=$(cat <<'EOF'
# PLAN

## Metadata
- Phase:
- Plan:
- Mode:
- Risk:

## Objective

## Scope

## Out of Scope

## Requirement Links

## Context Inputs

## Owned Files

## Shared Contracts

## Dependencies

## Tasks
- [ ] Task 1
- [ ] Task 2

## Evidence Commands
- [ ] command 1
- [ ] command 2

## Must-Haves
### Truths
- 

### Required Artifacts
- 

### Critical Links
- 

## Rollback

## Completion Criteria
EOF
)

SUMMARY_TEMPLATE_CONTENT=$(cat <<'EOF'
# SUMMARY

## Objective Recap

## Files Changed

## Commands Executed

## Results Observed

## Evidence Produced

## Risks / Residual Gaps

## Rollback Note

## Suggested Next Step
EOF
)

VALIDATION_TEMPLATE_CONTENT=$(cat <<'EOF'
# VALIDATION

## Goal Under Validation

## Requirement Coverage

## Observable Truths

## Required Artifacts

## Critical Links

## Automated Evidence

## Human Checks

## Pass Criteria

## Failure / Gap Rules
EOF
)

STATE_TEMPLATE_CONTENT=$(cat <<'EOF'
# STATE

## Current State

## Active Requirement(s)

## Active Phase

## Active Plan

## Completed Plans

## Blockers

## Pending Decisions

## Pending Human Checks

## Last Verified Evidence

## Next Valid Actions

## Resume Notes
EOF
)

CODEBASE_MAP_TEMPLATE_CONTENT=$(cat <<'EOF'
# CODEBASE MAP

## System Shape

## Architecture

## Stack

## Conventions

## Shared Contracts

## Integration Points

## Testing Surface

## Risk Zones

## Assumptions With Evidence
EOF
)

ARTIFACT_CONTRACTS_CONTENT=$(cat <<'EOF'
# Artifact Contracts

## Core Principles
- artifacts are contracts, not notes
- every artifact has a producer and consumers
- every artifact has a valid update window
- artifacts must stay stage-specific and compact
- artifacts should reduce context, not accumulate noise

## Artifact Catalog

### PROJECT.md
- Purpose: current product reality
- Producer: orchestrator / planner
- Consumers: all stages
- Update trigger: scope or product reality changes

### DECISIONS.md
- Purpose: durable decisions
- Producer: planner / architect
- Consumers: planner, implementer, verifier

### CONTEXT.md
- Purpose: phase-specific boundaries and locked choices
- Producer: discuss/intake step
- Consumers: planner, checker, implementer

### RESEARCH.md
- Purpose: domain and external knowledge
- Producer: researcher
- Consumers: planner, checker

### CODEBASE_MAP.md
- Purpose: brownfield structure and conventions
- Producer: investigator / mapper
- Consumers: planner, implementer, verifier

### PLAN.md
- Purpose: executable contract
- Producer: planner
- Consumers: implementer, checker, verifier

### SUMMARY.md
- Purpose: factual execution output
- Producer: implementer
- Consumers: verifier, reviewer, orchestrator

### VALIDATION.md
- Purpose: proof contract for verification
- Producer: planner / verifier
- Consumers: verifier, QA, reviewer

### UAT.md
- Purpose: human-only verification record
- Producer: human + orchestrator
- Consumers: verifier, reviewer

### STATE.md
- Purpose: workflow position and next valid moves
- Producer: orchestrator
- Consumers: all stages
EOF
)

VERIFICATION_MODEL_CONTENT=$(cat <<'EOF'
# Verification Model

## Core Principle
Task completion != Goal achievement

## Verification Stack
1. Goal
2. Observable Truths
3. Required Artifacts
4. Critical Links
5. Evidence Commands
6. Human Checks

## Verification States
- passed
- gaps_found
- human_needed

## Workflow
plan -> execute -> summary -> validation -> verification -> repair -> re-verification

## Gap Rules
A gap must identify:
- the failing truth
- affected requirement(s)
- missing or broken artifact(s)
- broken link(s)
- evidence of failure
- recommended repair scope
EOF
)

STATE_MACHINE_CONTENT=$(cat <<'EOF'
# State Machine

## States
- uninitialized
- mapped
- discussed
- planned
- executing
- verifying
- blocked
- shipped
- archived

## Valid Transitions
- uninitialized -> mapped
- mapped -> discussed
- discussed -> planned
- planned -> executing
- executing -> verifying
- verifying -> planned (repair)
- verifying -> shipped
- blocked -> planned/executing/verifying
- shipped -> archived

## Resume Rules
- read STATE.md first
- confirm active phase/plan
- confirm blockers and pending human checks
- resume only through a valid transition
EOF
)

mkdir -p "$TARGET_DIR/tasks" "$TARGET_DIR/templates"

copy_if_needed "$ROOT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
write_if_absent "$TARGET_DIR/README.md" "$README_CONTENT"
write_if_absent "$TARGET_DIR/tasks/todo.md" "$TASKS_TODO_CONTENT"
write_if_absent "$TARGET_DIR/tasks/lessons.md" "$TASKS_LESSONS_CONTENT"
write_if_absent "$TARGET_DIR/software-factory.json" "$CONFIG_CONTENT"
write_if_absent "$TARGET_DIR/templates/PLAN.md" "$PLAN_TEMPLATE_CONTENT"
write_if_absent "$TARGET_DIR/templates/SUMMARY.md" "$SUMMARY_TEMPLATE_CONTENT"

if [[ "$MODE" != "fast" ]]; then
  write_if_absent "$TARGET_DIR/templates/VALIDATION.md" "$VALIDATION_TEMPLATE_CONTENT"
  write_if_absent "$TARGET_DIR/templates/STATE.md" "$STATE_TEMPLATE_CONTENT"
fi

if [[ "$MODE" == "factory" || "$FULL_DOCS" == "true" ]]; then
  mkdir -p "$TARGET_DIR/docs"
  write_if_absent "$TARGET_DIR/docs/ARTIFACT_CONTRACTS.md" "$ARTIFACT_CONTRACTS_CONTENT"
  write_if_absent "$TARGET_DIR/docs/VERIFICATION_MODEL.md" "$VERIFICATION_MODEL_CONTENT"
  write_if_absent "$TARGET_DIR/docs/STATE_MACHINE.md" "$STATE_MACHINE_CONTENT"
fi

if [[ "$PROJECT_TYPE" == "brownfield" || "$MODE" == "factory" ]]; then
  write_if_absent "$TARGET_DIR/templates/CODEBASE_MAP.md" "$CODEBASE_MAP_TEMPLATE_CONTENT"
fi

if [[ "$WITH_SWARM" == "true" || "$MODE" == "factory" ]]; then
  mkdir -p "$TARGET_DIR/scripts" "$TARGET_DIR/docs"
  copy_if_needed "$ROOT_DIR/scripts/check-swarm.sh" "$TARGET_DIR/scripts/check-swarm.sh"
  copy_if_needed "$ROOT_DIR/docs/SWARM_RUNBOOK.md" "$TARGET_DIR/docs/SWARM_RUNBOOK.md"
  copy_if_needed "$ROOT_DIR/templates/swarm.tasks.example.json" "$TARGET_DIR/templates/swarm.tasks.example.json"
  chmod +x "$TARGET_DIR/scripts/check-swarm.sh" || true
fi

echo
echo "Software Factory bootstrap complete"
echo "- target: $TARGET_DIR"
echo "- mode: $MODE"
echo "- project type: $PROJECT_TYPE"
echo "- critical: $CRITICAL"
echo "- swarm: $WITH_SWARM"
