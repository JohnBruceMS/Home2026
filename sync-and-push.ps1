# Home Assistant Configuration Sync and Push Script
# This script pulls the latest config from Home Assistant and pushes to GitHub

param(
    [string]$CommitMessage = "Update Home Assistant configuration - $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

Write-Info "Starting Home Assistant configuration sync and push"

# Step 1: Pull latest config from Home Assistant
Write-Info "Pulling latest configuration from Home Assistant..."
if (-not $DryRun) {
    & "$PSScriptRoot\pull-homeassistant-config.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to pull Home Assistant configuration"
        exit 1
    }
}

# Step 2: Check for changes
Write-Info "Checking for changes..."
$gitStatus = git status --porcelain
if (-not $gitStatus) {
    Write-Info "No changes detected. Repository is up to date."
    if (-not $Force) {
        exit 0
    }
}

# Step 3: Stage changes
Write-Info "Staging changes..."
if (-not $DryRun) {
    git add .
    $stagedChanges = git diff --cached --name-only
    if ($stagedChanges) {
        Write-Info "Staged files:"
        $stagedChanges | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}

# Step 4: Commit changes
Write-Info "Committing changes with message: '$CommitMessage'"
if (-not $DryRun) {
    git commit -m $CommitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Warning-Custom "No changes to commit or commit failed"
    }
}

# Step 5: Push to GitHub
Write-Info "Pushing to GitHub repository..."
if (-not $DryRun) {
    git push origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Successfully pushed changes to GitHub!"
        Write-Info "Repository: https://github.com/JohnBruceMS/Home2026"
    } else {
        Write-Error-Custom "Failed to push to GitHub"
        exit 1
    }
}

if ($DryRun) {
    Write-Info "DRY RUN completed. No changes were made."
} else {
    Write-Info "Sync and push completed successfully!"
}