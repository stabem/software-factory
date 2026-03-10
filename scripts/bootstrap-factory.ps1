param(
  [string]$TargetDir = ".",
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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

Write-Host "Bootstrapping Software Factory into: $target"

Copy-TemplateFile -Source (Join-Path $root "AGENTS.md") -Destination (Join-Path $target "AGENTS.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "tasks\todo.md") -Destination (Join-Path $target "tasks\todo.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "tasks\lessons.md") -Destination (Join-Path $target "tasks\lessons.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "templates\PLAN.md") -Destination (Join-Path $target "tasks\plan.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "templates\CLAUDE.qa.md") -Destination (Join-Path $target "CLAUDE.md") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "templates\qa-guardian.workflow.yml") -Destination (Join-Path $target ".github\workflows\qa-guardian.yml") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "templates\factory-policy.workflow.yml") -Destination (Join-Path $target ".github\workflows\factory-policy.yml") -ForceCopy:$Force
Copy-TemplateFile -Source (Join-Path $root "scripts\check-factory-gate.sh") -Destination (Join-Path $target "scripts\check-factory-gate.sh") -ForceCopy:$Force

Write-Host ""
Write-Host "🎯 Next steps"
Write-Host "1) Fill commands/placeholders in tasks/plan.md and CLAUDE.md"
Write-Host "2) Configure secrets (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)"
Write-Host "3) Require Factory Policy Gate + QA/Security checks in branch protection"
