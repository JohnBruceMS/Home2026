# Home Assistant Credentials - Phase 1.1
# Secure storage for HA connection details

# Home Assistant Configuration
$Global:HA_CONFIG = @{
    BaseUrl = "http://192.168.1.198:8123"
    Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI1NzlmYmQzMDAxMDA0MGE0YmNiNDk1NzhhOTcwNjkwMiIsImlhdCI6MTc2Njk0MDI0NSwiZXhwIjoyMDgyMzAwMjQ1fQ.h0iOU2bpfdmvIZ_XAIBiw7QdKuX5HsxJKm3KtZ6JrBk"
    # Token expires: 2082-03-00 (long-lived)
}

function Initialize-HACredentials {
    # Load API functions if not already loaded
    if (-not (Get-Command "Set-HAConnection" -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot\HA-API-Functions.ps1"
    }
    
    # Set up connection
    Set-HAConnection -BaseUrl $Global:HA_CONFIG.BaseUrl -Token $Global:HA_CONFIG.Token
    
    Write-Host "Credentials loaded and connection configured" -ForegroundColor Green
}

# Auto-initialize when script is dot-sourced
if ($MyInvocation.InvocationName -eq ".") {
    Initialize-HACredentials
}

Write-Host "HA Credentials file loaded. Run 'Initialize-HACredentials' to connect." -ForegroundColor Cyan