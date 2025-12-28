# Home Assistant Cleanup Project - Phase 1.1 Setup
# Environment Setup & API Access

Write-Host "🏠 Home Assistant Cleanup Project - Phase 1.1" -ForegroundColor Cyan
Write-Host "Setting up PowerShell API access..." -ForegroundColor Yellow

# Import our HA API module
Import-Module ".\HomeAssistant-API.psm1" -Force

Write-Host ""
Write-Host "📋 Please provide your Home Assistant long-lived access token" -ForegroundColor Yellow
Write-Host "   (You can create one in HA: Settings > People > Long-lived access tokens)" -ForegroundColor Gray

# Secure token input
$token = Read-Host "Enter your long-lived access token" -AsSecureString
$plainToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))

# Set up connection
Set-HAConnection -BaseUrl "http://192.168.1.198:8123" -Token $plainToken

Write-Host ""
Write-Host "🔍 Testing connection..." -ForegroundColor Yellow

if (Test-HAConnection) {
    Write-Host ""
    Write-Host "🎉 SUCCESS! Phase 1.1 Environment Setup Complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run initial device audit: Export-HADeviceReport" -ForegroundColor White
    Write-Host "  2. Check for unavailable devices: Get-HAUnavailableDevices | Format-Table" -ForegroundColor White
    Write-Host "  3. View devices by domain: Get-HADevicesByDomain" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Ready to proceed to Milestone 1.2: Device & Integration Audit" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Connection failed. Please check your token and try again." -ForegroundColor Red
    Write-Host "   Run this script again with the correct token." -ForegroundColor Yellow
}

# Clear sensitive variables
$plainToken = $null
$token = $null