# Home Assistant Configuration Repository

This repository contains Home Assistant configuration files synchronized from a Home Assistant instance running on Linux and mapped to Windows drive Z:.

## Quick Start

### Option 1: Using the Batch File (Easiest)
```batch
# Double-click pull-config.bat or run from command prompt:
pull-config.bat
```

### Option 2: Using PowerShell Directly
```powershell
# Dry run to see what would be copied
.\pull-homeassistant-config.ps1 -DryRun

# Actually sync the files
.\pull-homeassistant-config.ps1

# Sync with verbose output
.\pull-homeassistant-config.ps1 -Verbose

# Sync from different source path
.\pull-homeassistant-config.ps1 -SourcePath "X:\path\to\homeassistant"
```

## Files in This Repository

### Scripts
- **`pull-homeassistant-config.ps1`** - Main PowerShell script for syncing configuration
- **`pull-config.bat`** - Windows batch wrapper for easy execution
- **`sync-config.ps1`** - Configuration file for customizing sync behavior

### Configuration Files (After First Sync)
- **`configuration.yaml`** - Main Home Assistant configuration
- **`automations.yaml`** - Automated tasks and triggers
- **`scripts.yaml`** - Reusable scripts
- **`scenes.yaml`** - Predefined scenes
- **`groups.yaml`** - Device and entity groupings
- **`customize.yaml`** - Entity customizations
- **`secrets.yaml.example`** - Template for secrets file

### Directories (After First Sync)
- **`packages/`** - Organized configuration packages
- **`custom_components/`** - Custom integrations and components
- **`lovelace/`** - Dashboard configurations
- **`themes/`** - Custom UI themes
- **`www/`** - Static web files
- **`blueprints/`** - Automation blueprints
- **`esphome/`** - ESPHome device configurations

## Prerequisites

1. **Home Assistant Access**: Your Home Assistant instance must be accessible from Windows
   - Mapped to drive Z: (default) or another drive letter
   - Network share, SSH mount, or direct file access

2. **PowerShell**: Windows PowerShell 5.1 or PowerShell Core 6+

3. **Git**: For version control (recommended)

## First-Time Setup

1. **Map your Home Assistant drive**:
   ```batch
   # Map network share to Z: drive
   net use Z: \\your-ha-server\config /persistent:yes
   ```

2. **Clone or initialize this repository**:
   ```bash
   git init
   git add .
   git commit -m "Initial Home Assistant config sync setup"
   ```

3. **Run the sync script**:
   ```batch
   pull-config.bat
   ```

4. **Set up secrets**:
   ```bash
   copy secrets.yaml.example secrets.yaml
   # Edit secrets.yaml with your actual values
   ```

## Customization

Edit `sync-config.ps1` to customize:
- **Source and destination paths**
- **Files and directories to include/exclude** 
- **Backup settings**
- **Validation options**

Example customization:
```powershell
# Add custom files to sync
$global:HAIncludeItems += @(
    "my_custom_config/",
    "special_automations.yaml"
)

# Exclude additional files
$global:HAExcludePatterns += @(
    "test_*.yaml",
    "backup_*/"
)
```

## Security Best Practices

1. **Never commit secrets**: The `secrets.yaml` file is automatically excluded from git
2. **Use the template**: Always work from `secrets.yaml.example`
3. **Review before committing**: Check what files are being added to git
4. **Regular updates**: Keep your configuration synchronized regularly

## Troubleshooting

### Drive Z: Not Accessible
```powershell
# Check if drive is mapped
Get-PSDrive Z

# Re-map the drive
net use Z: \\your-server\path /persistent:yes
```

### PowerShell Execution Policy
```powershell
# Allow script execution (run as Administrator)
Set-ExecutionPolicy RemoteSigned

# Or run with bypass (one-time)
powershell -ExecutionPolicy Bypass -File pull-homeassistant-config.ps1
```

### Sync Errors
```powershell
# Run with verbose output to see details
.\pull-homeassistant-config.ps1 -Verbose

# Use dry run to test without making changes
.\pull-homeassistant-config.ps1 -DryRun
```

## Git Workflow

```bash
# Check status
git status

# Add new configuration files
git add .

# Commit changes
git commit -m "Update Home Assistant configuration"

# Push to remote repository (if configured)
git push origin main
```

## Automation

### Windows Task Scheduler
Create a scheduled task to automatically sync configuration:

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., daily at 2 AM)
4. Set action: `powershell.exe`
5. Set arguments: `-ExecutionPolicy Bypass -File "C:\Dev\Home2026\pull-homeassistant-config.ps1"`

### PowerShell Profile
Add to your PowerShell profile for quick access:
```powershell
# Add to $PROFILE
function Sync-HomeAssistant {
    Set-Location "C:\Dev\Home2026"
    .\pull-homeassistant-config.ps1 @args
}

# Usage: Sync-HomeAssistant -Verbose
```

## Contributing

1. Test changes with `-DryRun` first
2. Update this README if you add new features
3. Follow PowerShell best practices
4. Test on different systems if possible

## License

See [LICENSE](LICENSE) file for details.

---
*Last updated: December 28, 2025*