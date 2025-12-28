# Home Assistant Integration Health Check
# Phase 1.3 - Integration Status & Diagnostics

function Get-HAIntegrations {
    try {
        $response = Invoke-RestMethod -Uri "$Global:HA_BASE_URL/api/config/config_entries" -Headers $Global:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get integrations: $($_.Exception.Message)"
        return $null
    }
}

function Get-HADeviceRegistry {
    try {
        $response = Invoke-RestMethod -Uri "$Global:HA_BASE_URL/api/config/device_registry/list" -Headers $Global:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get device registry: $($_.Exception.Message)"
        return $null
    }
}

function Test-IntegrationHealth {
    param(
        [string]$IntegrationDomain
    )
    
    Write-Host "Checking $IntegrationDomain integration health..." -ForegroundColor Yellow
    
    # Get all integrations
    $integrations = Get-HAIntegrations
    $targetIntegration = $integrations | Where-Object { $_.domain -eq $IntegrationDomain }
    
    if (-not $targetIntegration) {
        Write-Host "  ❌ $IntegrationDomain integration not found" -ForegroundColor Red
        return $false
    }
    
    foreach ($integration in $targetIntegration) {
        $status = switch ($integration.state) {
            "loaded" { "✅ LOADED" }
            "setup_error" { "❌ SETUP ERROR" }
            "setup_retry" { "⚠️ RETRYING" }
            "not_loaded" { "⏸️ NOT LOADED" }
            "failed_unload" { "❌ FAILED UNLOAD" }
            default { "❓ $($integration.state)" }
        }
        
        Write-Host "  $($integration.title): $status" -ForegroundColor $(if ($integration.state -eq "loaded") { "Green" } else { "Red" })
        
        if ($integration.state -ne "loaded") {
            Write-Host "    Entry ID: $($integration.entry_id)" -ForegroundColor Gray
            if ($integration.reason) {
                Write-Host "    Reason: $($integration.reason)" -ForegroundColor Red
            }
        }
    }
    
    return ($targetIntegration | Where-Object { $_.state -eq "loaded" }).Count -gt 0
}

function Get-IntegrationDeviceCount {
    param([string]$IntegrationDomain)
    
    $devices = Get-HADeviceRegistry
    if (-not $devices) { return 0 }
    
    $integrationDevices = $devices | Where-Object { 
        $_.config_entries -and ($_.config_entries | ForEach-Object { 
            $entry = $_
            $integrations = Get-HAIntegrations
            ($integrations | Where-Object { $_.entry_id -eq $entry -and $_.domain -eq $IntegrationDomain }).Count -gt 0
        }) -contains $true
    }
    
    return $integrationDevices.Count
}

Write-Host "Integration health check functions loaded" -ForegroundColor Green