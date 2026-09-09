. c:\Docker\scripts\Registry.ps1

$ProjectRoot = "c:\Docker"
$Errors = @()
$Warnings = @()

Write-Host "Starting Audit 1: Environment & Compose..." -ForegroundColor Cyan

# 1. Check if all files in Registry exist
foreach ($key in $Registry.Keys) {
    $svc = $Registry[$key]
    $composePath = Join-Path $ProjectRoot $svc.ComposeFile
    $envPath = Join-Path $ProjectRoot $svc.EnvFile
    $envExamplePath = $envPath + ".example"
    
    if (-not (Test-Path $composePath)) {
        $Errors += "Missing compose file for ${key}: $composePath"
    }
    
    if (-not (Test-Path $envExamplePath) -and -not (Test-Path $envPath)) {
        $Errors += "Missing both EnvFile and EnvFile.example for ${key}: $envPath"
    } elseif (-not (Test-Path $envExamplePath)) {
        $Warnings += "Missing EnvFile.example for ${key} (but .env exists): $envExamplePath"
    }
}

# 2. Check variables in compose files against env files
$GlobalEnvPath = Join-Path $ProjectRoot "config\global.env"
$GlobalVars = @()
if (Test-Path $GlobalEnvPath) {
    $GlobalVars = Get-Content $GlobalEnvPath | Where-Object { $_ -match "^([A-Z0-9_]+)=" } | ForEach-Object { $Matches[1] }
}

foreach ($key in $Registry.Keys) {
    $svc = $Registry[$key]
    $composePath = Join-Path $ProjectRoot $svc.ComposeFile
    $envExamplePath = Join-Path $ProjectRoot ($svc.EnvFile + ".example")
    
    if (-not (Test-Path $composePath)) { continue }
    
    $localVars = @()
    if (Test-Path $envExamplePath) {
        $localVars = Get-Content $envExamplePath | Where-Object { $_ -match "^([A-Z0-9_]+)=" } | ForEach-Object { $Matches[1] }
    }
    
    $composeContent = Get-Content $composePath -Raw
    # Find all ${VAR} or ${VAR:-default}
    $matches = [regex]::Matches($composeContent, "\$\{([A-Z0-9_]+)(:-.*?)?\}")
    
    foreach ($m in $matches) {
        $varName = $m.Groups[1].Value
        $hasDefault = $m.Groups[2].Success -and $m.Groups[2].Value.StartsWith(":-")
        
        if ($hasDefault) { continue }
        
        # Exceptions: Global vars and Shared Database vars
        if ($varName -in @("PROJECT_DATA_DIR", "PROJECT_APPS_DIR", "PROJECT_NETWORK_PREFIX", "PROJECT_NETWORK", "POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB", "TZ")) {
            if ($varName -notin $GlobalVars) {
                # We know PROJECT_NETWORK_PREFIX was added, but just in case
                if ($varName -ne "PROJECT_NETWORK") { # we deprecating PROJECT_NETWORK
                    $Warnings += "Global variable $varName used in $key but missing from global.env"
                }
            }
            continue
        }
        
        if ($varName -notin $localVars) {
            $Errors += "Variable $varName used in $($svc.ComposeFile) but missing from $($svc.EnvFile).example"
        }
    }
}

Write-Host "`n--- AUDIT RESULTS ---" -ForegroundColor Cyan
if ($Errors.Count -eq 0 -and $Warnings.Count -eq 0) {
    Write-Host "All checks passed! No discrepancies found." -ForegroundColor Green
} else {
    if ($Errors.Count -gt 0) {
        Write-Host "`nERRORS:" -ForegroundColor Red
        $Errors | ForEach-Object { Write-Host "- $_" }
    }
    if ($Warnings.Count -gt 0) {
        Write-Host "`nWARNINGS:" -ForegroundColor Yellow
        $Warnings | ForEach-Object { Write-Host "- $_" }
    }
}
