param (
    [string[]]$TargetServices,
    [string]$ProjectRoot = "c:\Docker",
    [string[]]$ComposeArgs
)

$JsonPath = Join-Path $ProjectRoot "test-results.json"
$TestsDir = Join-Path $ProjectRoot "tests"

if (-not (Test-Path $JsonPath)) {
    "{}" | Set-Content $JsonPath
}

$results = Get-Content $JsonPath | ConvertFrom-Json
$dateString = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

foreach ($service in $TargetServices) {
    # Skip caddy since it's the core router and often needed up all the time. 
    # Or test it anyway. We'll test it anyway if requested.
    
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "Testing Service: $service" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    if (-not $results.PSObject.Properties.Match($service)) {
        $results | Add-Member -MemberType NoteProperty -Name $service -Value @{ Status="Unknown"; LastTested="Never"; HasCustomTest=$false }
    }
    
    $serviceInfo = $results.$service
    $serviceInfo.HasCustomTest = $false
    
    # 1. Bring it up
    Write-Host "Starting $service (and dependencies)..."
    docker compose $ComposeArgs up -d $service 2>&1 | Out-Null
    
    # 2. Wait for health/running
    $passed = $false
    Write-Host "Waiting up to 30 seconds for state..."
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 2
        
        $stateRaw = docker compose $ComposeArgs ps --format json $service 
        if ($stateRaw) {
            $state = $stateRaw | ConvertFrom-Json
            
            # Handle list vs single object (newer docker compose returns array)
            if ($state -is [array]) { $state = $state[0] }
            
            if ($state -and $state.State -eq "running") {
                if ($state.Health -and $state.Health -ne "starting") {
                    if ($state.Health -eq "healthy") {
                        $passed = $true
                        break
                    }
                } else {
                    $passed = $true
                    break
                }
            }
        }
    }
    
    if (-not $passed) {
        Write-Host "Service $service failed to become healthy/running." -ForegroundColor Red
        $serviceInfo.Status = "Fail"
    } else {
        Write-Host "Service $service is running natively." -ForegroundColor Green
        
        # 3. Check for custom test script
        $customTestPath = Join-Path $TestsDir "test-${service}.ps1"
        if (Test-Path $customTestPath) {
            $serviceInfo.HasCustomTest = $true
            Write-Host "Found custom test script: test-${service}.ps1. Executing..." -ForegroundColor Yellow
            try {
                & $customTestPath -ProjectRoot $ProjectRoot -ComposeArgs $ComposeArgs
                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
                    Write-Host "Custom test passed!" -ForegroundColor Green
                    $serviceInfo.Status = "Pass"
                } else {
                    Write-Host "Custom test failed with exit code $LASTEXITCODE." -ForegroundColor Red
                    $serviceInfo.Status = "Fail"
                }
            } catch {
                Write-Host "Custom test threw an exception: $_" -ForegroundColor Red
                $serviceInfo.Status = "Fail"
            }
        } else {
            $serviceInfo.Status = "Pass"
        }
    }
    
    $serviceInfo.LastTested = $dateString
    
    # 4. Bring it down
    Write-Host "Stopping and removing $service container..."
    docker compose $ComposeArgs stop $service 2>&1 | Out-Null
    docker compose $ComposeArgs rm -f $service 2>&1 | Out-Null
}

$results | ConvertTo-Json -Depth 5 | Set-Content $JsonPath
Write-Host "`nService testing completed and test-results.json updated!" -ForegroundColor Green
