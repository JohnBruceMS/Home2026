# Home Assistant Configuration Sync Settings
# Edit this file to customize what gets synced from your Home Assistant instance

# Source and destination paths
$global:HAConfigPaths = @{
    # Default source path (your mapped drive)
    SourcePath = "Z:\"
    
    # Destination path (current repository)
    DestinationPath = $PSScriptRoot
}

# Files and directories to include in sync
$global:HAIncludeItems = @(
    "configuration.yaml",
    "automations.yaml", 
    "scripts.yaml",
    "scenes.yaml",
    "groups.yaml",
    "customize.yaml",
    "secrets.yaml.example",
    "lovelace/",
    "packages/",
    "custom_components/",
    "themes/",
    "www/",
    "blueprints/",
    "esphome/",
    "python_scripts/",
    "shell_commands/",
    "integrations/",
    ".github/"
)

# Files and patterns to exclude (sensitive or unnecessary)
$global:HAExcludePatterns = @(
    # Sensitive files
    "secrets.yaml",
    "known_devices.yaml",
    "ip_bans.yaml",
    
    # Log files
    "*.log",
    "*.log.*",
    "home-assistant.log*",
    
    # Database files
    "*.db",
    "*.db-*",
    
    # Home Assistant internal files
    ".storage/",
    ".cloud/",
    "deps/",
    "tts/",
    ".uuid",
    ".HA_VERSION",
    ".homeassistant",
    
    # Python cache
    "__pycache__/",
    "*.pyc",
    "*.pyo",
    
    # Temporary files
    "*.tmp",
    "*.temp",
    
    # Backup files
    "*.backup",
    ".homeassistant_backup/",
    
    # OS files
    ".DS_Store",
    "Thumbs.db",
    
    # Custom exclusions (add your own here)
    # "custom_file_to_exclude.yaml"
)

# Additional options
$global:HAOptions = @{
    # Create backup before sync
    CreateBackup = $true
    
    # Backup directory (relative to destination)
    BackupDirectory = ".backups"
    
    # Maximum number of backups to keep
    MaxBackups = 5
    
    # Validate YAML files after sync
    ValidateYAML = $true
    
    # Generate sync report
    GenerateReport = $true
}