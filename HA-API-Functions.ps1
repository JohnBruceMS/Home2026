# Home Assistant API Functions
# Phase 1.1 - Direct PowerShell Implementation

# Global variables
$Global:HA_BASE_URL = "http://192.168.1.198:8123"
$Global:HA_TOKEN = $null
$Global:HA_HEADERS = @{}

function Set-HAConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BaseUrl,
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    $Global:HA_BASE_URL = $BaseUrl.TrimEnd('/')
    $Global:HA_TOKEN = $Token
    $Global:HA_HEADERS = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
    }
    
    Write-Host "Home Assistant connection configured for: $Global:HA_BASE_URL" -ForegroundColor Green
}

function Test-HAConnection {
    try {
        $response = Invoke-RestMethod -Uri "$Global:HA_BASE_URL/api/" -Headers $Global:HA_HEADERS -Method GET
    Write-Host "Connection successful! HA Version: $($response.version)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Connection failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-HAStates {
    try {
        $response = Invoke-RestMethod -Uri "$Global:HA_BASE_URL/api/states" -Headers $Global:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get states: $($_.Exception.Message)"
        return $null
    }
}

function Get-HAConfig {
    try {
        $response = Invoke-RestMethod -Uri "$Global:HA_BASE_URL/api/config" -Headers $Global:HA_HEADERS -Method GET
        return $response
    }
    catch {
        Write-Error "Failed to get config: $($_.Exception.Message)"
        return $null
    }
}

function Get-HAUnavailableDevices {
    $states = Get-HAStates
    if (-not $states) { return $null }
    
    $unavailable = $states | Where-Object { 
        $_.state -eq 'unavailable' -or 
        $_.state -eq 'unknown' -or 
        $_.state -eq 'None' 
    }
    
    return $unavailable
}

function Get-HADevicesByDomain {
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

Write-Host "Home Assistant API functions loaded" -ForegroundColor Green