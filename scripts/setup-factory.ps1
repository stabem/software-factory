# Setup Software Factory for Windows
# Usage: .\scripts\setup-factory.ps1

$ErrorActionPreference = "Stop"

$agents = @("architect", "builder", "tester", "reviewer", "security", "docwriter")

# Verify git repo
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not a git repository" -ForegroundColor Red
    exit 1
}

Write-Host "🏭 Setting up Software Factory..." -ForegroundColor Cyan

# Create directories
New-Item -ItemType Directory -Force -Path "worktrees" | Out-Null
New-Item -ItemType Directory -Force -Path ".agent-comms/messages" | Out-Null

# Create worktrees
foreach ($agent in $agents) {
    $path = "worktrees/$agent"
    if (Test-Path $path) {
        Write-Host "⚠️  Worktree exists: $path" -ForegroundColor Yellow
    } else {
        Write-Host "📁 Creating worktree: $agent" -ForegroundColor Green
        git worktree add $path -b "agent/$agent" 2>$null
        if ($LASTEXITCODE -ne 0) {
            git worktree add $path "agent/$agent" 2>$null
        }
    }
}

# Update .gitignore
$gitignore = Get-Content ".gitignore" -ErrorAction SilentlyContinue
if ($gitignore -notcontains "worktrees/") {
    Add-Content ".gitignore" "worktrees/"
    Write-Host "📝 Added worktrees/ to .gitignore" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Cyan
Write-Host ""
git worktree list
Write-Host ""
Write-Host "Next: Update .agent-comms/PLAN.md with your tasks" -ForegroundColor Yellow
