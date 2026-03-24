param(
  [string]$TargetDir = ".",
  [ValidateSet('fast','standard','factory')]
  [string]$Mode = 'standard',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not (Test-Path $TargetDir)) {
  New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
$target = (Resolve-Path $TargetDir).Path

function Copy-TemplateFile {
  param(
    [string]$Source,
    [string]$Destination,
    [switch]$ForceCopy
  )

  $parent = Split-Path -Parent $Destination
  if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  if ((Test-Path $Destination) -and (-not $ForceCopy)) {
    Write-Host "↩️  skip (exists): $Destination"
    return
  }

  Copy-Item -Path $Source -Destination $Destination -Force
  Write-Host "✅ copied: $Destination"
}

Write-Host "Bootstrapping Software Factory into: $target (mode: $Mode)"

Copy-TemplateFile -Source (Join-Path $root "AGENTS.md") -Destination (Join-Path $target "AGENTS.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "tasks\todo.md") -Destination (Join-Path $target "tasks\todo.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "tasks\lessons.md") -Destination (Join-Path $target "tasks\lessons.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "templates\PLAN.md") -Destination (Join-Path $target "tasks\plan.md") -ForceCopy:$Force

if ($Mode -ne 'fast') {
  Copy-TemplateFile -Source (Join-Path $root "templates\CLAUDE.qa.md") -Destination (Join-Path $target "CLAUDE.md") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "templates\qa-guardian.workflow.yml") -Destination (Join-Path $target ".github\workflows\qa-guardian.yml") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "templates\factory-policy.workflow.yml") -Destination (Join-Path $target ".github\workflows\factory-policy.yml") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "scripts\check-factory-gate.sh") -Destination (Join-Path $target "scripts\check-factory-gate.sh") -ForceCopy:$Force
}

if ($Mode -eq 'factory') {
  Copy-TemplateFile -Source (Join-Path $root "templates\swarm.tasks.example.json") -Destination (Join-Path $target "templates\swarm.tasks.example.json") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "scripts\check-swarm.sh") -Destination (Join-Path $target "scripts\check-swarm.sh") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "docs\SWARM_RUNBOOK.md") -Destination (Join-Path $target "docs\SWARM_RUNBOOK.md") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "docs\VERIFICATION_MODEL.md") -Destination (Join-Path $target "docs\VERIFICATION_MODEL.md") -ForceCopy:$Force
  Copy-TemplateFile -Source (Join-Path $root "docs\STATE_MACHINE.md") -Destination (Join-Path $target "docs\STATE_MACHINE.md") -ForceCopy:$Force
}

Write-Host ""
Write-Host "🎯 Next steps"
Write-Host "1) Fill commands/placeholders in tasks/plan.md"
if ($Mode -ne "fast") {
  Write-Host "2) Fill commands/placeholders in CLAUDE.md"
  Write-Host "3) Configure secrets (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)"
  Write-Host "4) Require Factory Policy Gate + QA/Security checks in branch protection"
}
if ($Mode -eq "factory") {
  Write-Host "5) Initialize swarm registry/monitor assets if needed"
}
