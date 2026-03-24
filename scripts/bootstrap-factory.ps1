param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$TargetDir,
  [ValidateSet('fast','standard','factory')]
  [string]$Mode = 'standard',
  [ValidateSet('greenfield','brownfield')]
  [string]$ProjectType = 'greenfield',
  [switch]$Critical,
  [switch]$WithSwarm,
  [switch]$FullDocs,
  [switch]$Force
)

$RootDir = Split-Path -Parent $PSScriptRoot
$ResolvedTarget = (New-Item -ItemType Directory -Force -Path $TargetDir).FullName

function Write-IfAbsent {
  param(
    [string]$Path,
    [string]$Content
  )
  if ((Test-Path $Path) -and -not $Force) {
    Write-Host "skip: $Path already exists"
    return
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
  Set-Content -Path $Path -Value $Content -NoNewline
  Write-Host "write: $Path"
}

function Copy-IfNeeded {
  param(
    [string]$Source,
    [string]$Destination
  )
  if ((Test-Path $Destination) -and -not $Force) {
    Write-Host "skip: $Destination already exists"
    return
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
  Copy-Item -Path $Source -Destination $Destination -Force
  Write-Host "copy: $Destination"
}

$MaxAgents = if ($Mode -eq 'factory') { 3 } else { 1 }
$ConfigContent = @"
{
  "mode": "$Mode",
  "projectType": "$ProjectType",
  "critical": $($Critical.IsPresent.ToString().ToLower()),
  "swarm": {
    "enabled": $($WithSwarm.IsPresent.ToString().ToLower()),
    "maxAgents": $MaxAgents
  },
  "verification": {
    "model": "goal-backward",
    "prRequired": true
  }
}
"@

$ReadmeContent = @"
# $(Split-Path $ResolvedTarget -Leaf)

Bootstrapped with **Software Factory**.

## Selected Profile
- **Mode:** $Mode
- **Project type:** $ProjectType
- **Critical repo:** $($Critical.IsPresent)
- **Swarm enabled:** $($WithSwarm.IsPresent)

## Next Steps
1. Review `AGENTS.md`
2. Fill `tasks/todo.md` with the first active plan
3. If brownfield, map the codebase before planning changes
4. Open work on a branch and follow PR-first delivery

## Workflow Defaults
- Verification model: goal-backward
- PR required: yes
- Use mode escalation when scope or risk increases
"@

$TodoContent = @"
# Project — Active Tasks

## Phase: Planning

### Current Sprint
- [ ] Bootstrap complete — review generated files and adjust project-specific defaults
- [ ] Add first real task plan

### Blocked
- [ ] None

### Review
- Mode selected and project bootstrapped.
"@

$LessonsContent = @"
# Lessons Learned

Add lessons here as the project evolves.
"@

$PlanTemplate = @"
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
"@

$SummaryTemplate = @"
# SUMMARY

## Objective Recap

## Files Changed

## Commands Executed

## Results Observed

## Evidence Produced

## Risks / Residual Gaps

## Rollback Note

## Suggested Next Step
"@

$ValidationTemplate = @"
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
"@

$StateTemplate = @"
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
"@

$CodebaseMapTemplate = @"
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
"@

$ArtifactContracts = @"
# Artifact Contracts

## Core Principles
- artifacts are contracts, not notes
- every artifact has a producer and consumers
- every artifact has a valid update window
- artifacts must stay stage-specific and compact
- artifacts should reduce context, not accumulate noise
"@

$VerificationModel = @"
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
"@

$StateMachine = @"
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
"@

Copy-IfNeeded "$RootDir/AGENTS.md" "$ResolvedTarget/AGENTS.md"
Write-IfAbsent "$ResolvedTarget/README.md" $ReadmeContent
Write-IfAbsent "$ResolvedTarget/tasks/todo.md" $TodoContent
Write-IfAbsent "$ResolvedTarget/tasks/lessons.md" $LessonsContent
Write-IfAbsent "$ResolvedTarget/software-factory.json" $ConfigContent
Write-IfAbsent "$ResolvedTarget/templates/PLAN.md" $PlanTemplate
Write-IfAbsent "$ResolvedTarget/templates/SUMMARY.md" $SummaryTemplate

if ($Mode -ne 'fast') {
  Write-IfAbsent "$ResolvedTarget/templates/VALIDATION.md" $ValidationTemplate
  Write-IfAbsent "$ResolvedTarget/templates/STATE.md" $StateTemplate
}

if ($Mode -eq 'factory' -or $FullDocs) {
  Write-IfAbsent "$ResolvedTarget/docs/ARTIFACT_CONTRACTS.md" $ArtifactContracts
  Write-IfAbsent "$ResolvedTarget/docs/VERIFICATION_MODEL.md" $VerificationModel
  Write-IfAbsent "$ResolvedTarget/docs/STATE_MACHINE.md" $StateMachine
}

if ($ProjectType -eq 'brownfield' -or $Mode -eq 'factory') {
  Write-IfAbsent "$ResolvedTarget/templates/CODEBASE_MAP.md" $CodebaseMapTemplate
}

if ($WithSwarm -or $Mode -eq 'factory') {
  Copy-IfNeeded "$RootDir/scripts/check-swarm.sh" "$ResolvedTarget/scripts/check-swarm.sh"
  Copy-IfNeeded "$RootDir/docs/SWARM_RUNBOOK.md" "$ResolvedTarget/docs/SWARM_RUNBOOK.md"
  Copy-IfNeeded "$RootDir/templates/swarm.tasks.example.json" "$ResolvedTarget/templates/swarm.tasks.example.json"
}

Write-Host ""
Write-Host "Software Factory bootstrap complete"
Write-Host "- target: $ResolvedTarget"
Write-Host "- mode: $Mode"
Write-Host "- project type: $ProjectType"
Write-Host "- critical: $($Critical.IsPresent)"
Write-Host "- swarm: $($WithSwarm.IsPresent)"
