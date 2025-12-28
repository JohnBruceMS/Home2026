# HomeAssistant PowerShell API Module
# Created for HA Cleanup Project - Phase 1.1

# Global variables
$Script:HA_BASE_URL = "http://192.168.1.198:8123"
$Script:HA_TOKEN = $null
$Script:HA_HEADERS = @{}

function Set-HAConnection {
    <#
    .SYNOPSIS
    Set up Home Assistant connection parameters
    .PARAMETER BaseUrl
    The base URL for your Home Assistant instance
    .PARAMETER Token
    Long-lived access token for authentication
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$BaseUrl,
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $Script:HA_BASE_URL = $BaseUrl.TrimEnd('/')
    $Script:HA_TOKEN = $Token
    $Script:HA_HEADERS = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
    }
    
    Write-Host "✅ Home Assistant connection configured for: $Script:HA_BASE_URL" -ForegroundColor Green
}

function Test-HAConnection {
    <#
    .SYNOPSIS
    Test the connection to Home Assistant
    #>
    try {
        $response = Invoke-RestMethod -Uri "$Script:HA_BASE_URL/api/" -Headers $Script:HA_HEADERS -Method GET
        Write-Host "✅ Connection successful! HA Version: $($response.version)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Connection failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-HAStates {
    <#
    .SYNOPSIS
    Get all entity states from Home Assistant
    #>
    try {
        $response = Invoke-RestMethod -Uri "$Script:HA_BASE_URL/api/states" -Headers $Script:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get states: $($_.Exception.Message)"
        return $null
    }
}

function Get-HAServices {
    <#
    .SYNOPSIS
    Get all available services from Home Assistant
    #>
    try {
        $response = Invoke-RestMethod -Uri "$Script:HA_BASE_URL/api/services" -Headers $Script:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get services: $($_.Exception.Message)"
        return $null
    }
}

function Get-HAConfig {
    <#
    .SYNOPSIS
    Get Home Assistant configuration
    #>
    try {
        $response = Invoke-RestMethod -Uri "$Script:HA_BASE_URL/api/config" -Headers $Script:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get config: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-HAService {
    <#
    .SYNOPSIS
    Call a Home Assistant service
    .PARAMETER Domain
    The service domain (e.g., 'light', 'switch')
    .PARAMETER Service
    The service name (e.g., 'turn_on', 'turn_off')
    .PARAMETER ServiceData
    Hashtable of service data
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain,
        [Parameter(Mandatory=$true)]
        [string]$Service,
        [hashtable]$ServiceData = @{}
    )
    
    try {
        $body = $ServiceData | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri "$Script:HA_BASE_URL/api/services/$Domain/$Service" -Headers $Script:HA_HEADERS -Method POST -Body $body
        return $response
    }
    catch {
        Write-Error "Failed to call service $Domain/$Service: $($_.Exception.Message)"
        return $null
    }
}

function Get-HADevicesByDomain {
    <#
    .SYNOPSIS
    Get all entities grouped by domain for device audit
    #>
    $states = Get-HAStates
    if (-not $states) { return $null }
    
    $devicesByDomain = @{}
    foreach ($entity in $states) {
        $domain = $entity.entity_id.Split('.')[0]
        if (-not $devicesByDomain.ContainsKey($domain)) {
            $devicesByDomain[$domain] = @()
        }
        $devicesByDomain[$domain] += $entity
    }
    
    return $devicesByDomain
}

function Get-HAUnavailableDevices {
    <#
    .SYNOPSIS
    Find all unavailable or unknown state devices
    #>
    $states = Get-HAStates
    if (-not $states) { return $null }
    
    $unavailable = $states | Where-Object { 
        $_.state -eq 'unavailable' -or 
        $_.state -eq 'unknown' -or 
        $_.state -eq 'None' 
    }
    
    return $unavailable
}

function Export-HADeviceReport {
    <#
    .SYNOPSIS
    Generate comprehensive device audit report
    .PARAMETER OutputPath
    Path to save the report
    #>
    param(
        [string]$OutputPath = "HA-Device-Audit-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
    )
    
    Write-Host "🔍 Generating device audit report..." -ForegroundColor Yellow
    
    $report = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ha_version = (Get-HAConfig).version
        total_entities = 0
        devices_by_domain = @{}
        unavailable_devices = @()
        integration_summary = @{}
    }
    
    # Get all states
    $states = Get-HAStates
    $report.total_entities = $states.Count
    
    # Group by domain
    $report.devices_by_domain = Get-HADevicesByDomain
    
    # Find unavailable devices
    $report.unavailable_devices = Get-HAUnavailableDevices
    
    # Create integration summary
    foreach ($domain in $report.devices_by_domain.Keys) {
        $report.integration_summary[$domain] = @{
            count = $report.devices_by_domain[$domain].Count
            unavailable_count = ($report.unavailable_devices | Where-Object { $_.entity_id.StartsWith("$domain.") }).Count
        }
    }
    
    # Save report
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Device audit report saved to: $OutputPath" -ForegroundColor Green
    
    return $report
}

# Export module functions
Export-ModuleMember -Function Set-HAConnection, Test-HAConnection, Get-HAStates, Get-HAServices, Get-HAConfig, Invoke-HAService, Get-HADevicesByDomain, Get-HAUnavailableDevices, Export-HADeviceReport