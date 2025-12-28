# Home Assistant Configuration Pull Script
# This script pulls configuration files from a Home Assistant instance mapped to Z: drive
# and syncs them to the local repository

param(
    [string]$SourcePath = "Z:\",
    [string]$DestinationPath = $PSScriptRoot,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Configuration - Files and directories to sync
$ConfigItems = @(
    "configuration.yaml",
    "automations.yaml", 
    "scripts.yaml",
    "scenes.yaml",
    "groups.yaml",
    "customize.yaml",
    "secrets.yaml.example",  # Copy as example, excluding actual secrets
    "lovelace/",
    "packages/",
    "custom_components/",
    "themes/",
    "www/",
    "blueprints/",
    "esphome/"
)

# Files to exclude (sensitive or unnecessary)
$ExcludePatterns = @(
    "secrets.yaml",
    "known_devices.yaml",
    "*.log",
    "*.db",
    "*.db-*",
    ".storage/",
    "__pycache__/",
    "*.pyc",
    ".cloud/",
    "deps/",
    "tts/",
    ".uuid",
    ".HA_VERSION",
    "home-assistant.log*"
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

function Test-HomeAssistantSource {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error-Custom "Source path '$Path' does not exist or is not accessible"
        return $false
    }
    
    $configFile = Join-Path $Path "configuration.yaml"
    if (-not (Test-Path $configFile)) {
        Write-Error-Custom "configuration.yaml not found at '$configFile'. This doesn't appear to be a Home Assistant configuration directory."
        return $false
    }
    
    return $true
}

function Copy-HomeAssistantItem {
    param(
        [string]$SourceRoot,
        [string]$DestRoot,
        [string]$Item,
        [string[]]$ExcludePatterns,
        [bool]$IsDryRun
    )
    
    $sourcePath = Join-Path $SourceRoot $Item
    $destPath = Join-Path $DestRoot $Item
    
    if (-not (Test-Path $sourcePath)) {
        if ($Verbose) {
            Write-Warning-Custom "Source item '$Item' does not exist, skipping"
        }
        return
    }
    
    # Handle secrets.yaml specially
    if ($Item -eq "secrets.yaml.example" -and (Test-Path (Join-Path $SourceRoot "secrets.yaml"))) {
        $secretsSource = Join-Path $SourceRoot "secrets.yaml"
        $secretsContent = Get-Content $secretsSource -Raw
        # Replace actual values with placeholders
        $secretsContent = $secretsContent -replace ':\s*[^#\s][^#\n]*', ': YOUR_VALUE_HERE  # TODO: Replace with actual value'
        
        if (-not $IsDryRun) {
            $secretsContent | Out-File -FilePath $destPath -Encoding UTF8
        }
        Write-Info "Created secrets.yaml.example template"
        return
    }
    
    if (Test-Path $sourcePath -PathType Container) {
        # Directory
        Write-Info "Syncing directory: $Item"
        
        if (-not $IsDryRun) {
            if (-not (Test-Path $destPath)) {
                New-Item -Path $destPath -ItemType Directory -Force | Out-Null
            }
            
            # Use robocopy for directory sync with exclusions
            $excludeArgs = $ExcludePatterns | ForEach-Object { "/XF", $_ } | ForEach-Object { $_ }
            $robocopyArgs = @($sourcePath, $destPath, "/MIR", "/XD", ".git") + $excludeArgs
            
            if (-not $Verbose) {
                $robocopyArgs += "/NJH", "/NJS", "/NP"
            }
            
            & robocopy @robocopyArgs | Out-Null
            
            if ($LASTEXITCODE -gt 7) {
                Write-Error-Custom "Robocopy failed for directory '$Item' with exit code $LASTEXITCODE"
            }
        }
    } else {
        # File
        Write-Info "Copying file: $Item"
        
        if (-not $IsDryRun) {
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item $sourcePath $destPath -Force
        }
    }
}

function Update-GitIgnore {
    param([string]$RepoPath)
    
    $gitignorePath = Join-Path $RepoPath ".gitignore"
    $gitignoreContent = @"
# Home Assistant sensitive files
secrets.yaml
known_devices.yaml
*.log
*.db
*.db-*
.uuid
.HA_VERSION
home-assistant.log*

# Home Assistant directories that shouldn't be tracked
.storage/
.cloud/
deps/
tts/
__pycache__/
*.pyc

# OS generated files
.DS_Store
Thumbs.db
"@

    if (-not (Test-Path $gitignorePath)) {
        Write-Info "Creating .gitignore file"
        if (-not $DryRun) {
            $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding UTF8
        }
    } else {
        Write-Info ".gitignore already exists"
    }
}

function New-ReadmeFile {
    param([string]$RepoPath)
    
    $readmePath = Join-Path $RepoPath "README.md"
    
    if (-not (Test-Path $readmePath)) {
        $readmeContent = @"
# Home Assistant Configuration

This repository contains my Home Assistant configuration files.

## Structure

- ``configuration.yaml`` - Main configuration file
- ``automations.yaml`` - Automated tasks and triggers
- ``scripts.yaml`` - Reusable scripts
- ``scenes.yaml`` - Predefined scenes
- ``packages/`` - Organized configuration packages
- ``custom_components/`` - Custom integrations
- ``lovelace/`` - Dashboard configurations
- ``themes/`` - Custom themes
- ``blueprints/`` - Automation blueprints

## Setup

1. Copy ``secrets.yaml.example`` to ``secrets.yaml``
2. Fill in your actual values in ``secrets.yaml``
3. Customize the configuration files as needed

## Sync Script

Use ``pull-homeassistant-config.ps1`` to sync configuration from your Home Assistant instance:

```powershell
# Dry run to see what would be copied
.\pull-homeassistant-config.ps1 -DryRun

# Actually sync the files
.\pull-homeassistant-config.ps1

# Sync from different path
.\pull-homeassistant-config.ps1 -SourcePath "X:\homeassistant"
```

## Security Note

The ``secrets.yaml`` file is excluded from version control for security. Always use the example template and never commit sensitive information.

---
Last updated: $(Get-Date -Format 'yyyy-MM-dd')
"@
        
        Write-Info "Creating README.md file"
        if (-not $DryRun) {
            $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        }
    }
}

# Main execution
Write-Info "Home Assistant Configuration Pull Script"
Write-Info "Source: $SourcePath"
Write-Info "Destination: $DestinationPath"

if ($DryRun) {
    Write-Info "DRY RUN MODE - No files will be modified"
}

# Validate source
if (-not (Test-HomeAssistantSource $SourcePath)) {
    exit 1
}

Write-Info "Found Home Assistant configuration at $SourcePath"

# Create destination directory if it doesn't exist
if (-not (Test-Path $DestinationPath)) {
    Write-Info "Creating destination directory: $DestinationPath"
    if (-not $DryRun) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
}

# Copy each configured item
foreach ($item in $ConfigItems) {
    Copy-HomeAssistantItem -SourceRoot $SourcePath -DestRoot $DestinationPath -Item $item -ExcludePatterns $ExcludePatterns -IsDryRun $DryRun
}

# Update .gitignore
Update-GitIgnore -RepoPath $DestinationPath

# Create README if it doesn't exist
New-ReadmeFile -RepoPath $DestinationPath

Write-Info "Configuration sync completed successfully!"

if ($DryRun) {
    Write-Info "This was a dry run. Re-run without -DryRun to actually sync files."
} else {
    Write-Info "Files have been synced to: $DestinationPath"
    Write-Info "Don't forget to review and commit changes to git!"
}