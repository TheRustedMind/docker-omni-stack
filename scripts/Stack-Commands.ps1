function Show-Services {
    Write-Host "Registered Services:"
    $Registry.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $deps = if ($_.Value.DependsOn.Count -gt 0) { $_.Value.DependsOn -join ", " } else { "None" }
        Write-Host "- $($_.Name) (Group: $($_.Value.Group)) [Dependencies: $deps]"
    }
}

function Show-Groups {
    Write-Host "Registered Groups:"
    $Groups = $Registry.Values.Group | Select-Object -Unique | Sort-Object
    foreach ($grp in $Groups) {
        $svcCount = @($Registry.GetEnumerator() | Where-Object { $_.Value.Group -eq $grp }).Count
        Write-Host "- $grp ($svcCount services)"
    }
}

function Invoke-StackSetup {
    param(
        [string]$ProjectName
    )
    Write-Host "Starting First-Time Setup..." -ForegroundColor Cyan
    
    $ConfigDir = Join-Path $ProjectRoot "config"
    $Examples = Get-ChildItem -Path $ConfigDir -Filter "*.env.example"
    
    Write-Host "Copying .env.example files..."
    foreach ($Example in $Examples) {
        $TargetFile = $Example.FullName -replace '\.example$', ''
        if (-not (Test-Path $TargetFile)) {
            Copy-Item -Path $Example.FullName -Destination $TargetFile
            Write-Host "  Created $($Example.Name -replace '\.example$', '')" -ForegroundColor Green
        }
    }

    $GlobalEnv = Join-Path $ConfigDir "global.env"
    $useVolStr = if ($UseVolumes) { "true" } else { "false" }
    if (-not (Test-Path $GlobalEnv)) {
        Write-Host "Creating global.env..."
        Set-Content -Path $GlobalEnv -Value "PROJECT_NETWORK_PREFIX=$ProjectName`nPROJECT_DATA_DIR=../data`nPROJECT_APPS_DIR=../apps`nUSE_DOCKER_VOLUMES=$useVolStr"
    } elseif ($UseVolumes) {
        $content = Get-Content $GlobalEnv -Raw
        if ($content -match "USE_DOCKER_VOLUMES=") {
            $content = $content -replace "USE_DOCKER_VOLUMES=.*", "USE_DOCKER_VOLUMES=true"
        } else {
            if (-not $content.EndsWith("`n")) { $content += "`r`n" }
            $content += "USE_DOCKER_VOLUMES=true`r`n"
        }
        Set-Content -Path $GlobalEnv -Value $content -NoNewline
    }

    $DataDir = "../data"
    $AppsDir = "../apps"
    if (Test-Path $GlobalEnv) {
        Get-Content $GlobalEnv | ForEach-Object {
            if ($_ -match "^PROJECT_DATA_DIR=(.*)") { $DataDir = $Matches[1] }
            if ($_ -match "^PROJECT_APPS_DIR=(.*)") { $AppsDir = $Matches[1] }
        }
    }

    $DataPath = if ([System.IO.Path]::IsPathRooted($DataDir)) { $DataDir } else { Join-Path $ProjectRoot "compose/$DataDir" }
    $AppsPath = if ([System.IO.Path]::IsPathRooted($AppsDir)) { $AppsDir } else { Join-Path $ProjectRoot "compose/$AppsDir" }
    
    $DataPath = [System.IO.Path]::GetFullPath($DataPath)
    $AppsPath = [System.IO.Path]::GetFullPath($AppsPath)

    Write-Host "Ensuring directories exist..."
    if (-not (Test-Path $DataPath)) { New-Item -ItemType Directory -Path $DataPath | Out-Null; Write-Host "  Created $DataPath" }
    if (-not (Test-Path $AppsPath)) { New-Item -ItemType Directory -Path $AppsPath | Out-Null; Write-Host "  Created $AppsPath" }
    
    $CaddyAppDir = Join-Path $AppsPath "caddy"
    if (-not (Test-Path $CaddyAppDir)) { New-Item -ItemType Directory -Path $CaddyAppDir | Out-Null; Write-Host "  Created $CaddyAppDir" }
    
    $PrometheusAppDir = Join-Path $AppsPath "prometheus"
    if (-not (Test-Path $PrometheusAppDir)) { New-Item -ItemType Directory -Path $PrometheusAppDir | Out-Null; Write-Host "  Created $PrometheusAppDir" }
    $PrometheusFile = Join-Path $PrometheusAppDir "prometheus.yml"
    if (-not (Test-Path $PrometheusFile)) { New-Item -ItemType File -Path $PrometheusFile | Out-Null; Write-Host "  Created $PrometheusFile" }

    $LitellmAppDir = Join-Path $AppsPath "litellm"
    if (-not (Test-Path $LitellmAppDir)) { New-Item -ItemType Directory -Path $LitellmAppDir | Out-Null; Write-Host "  Created $LitellmAppDir" }
    $LitellmFile = Join-Path $LitellmAppDir "config.yaml"
    if (-not (Test-Path $LitellmFile)) { New-Item -ItemType File -Path $LitellmFile | Out-Null; Write-Host "  Created $LitellmFile" }
    
    $CaddyfileExample = Join-Path $ConfigDir "Caddyfile.example"
    $CaddyfileTarget = Join-Path $CaddyAppDir "Caddyfile"
    if ((Test-Path $CaddyfileExample) -and -not (Test-Path $CaddyfileTarget)) {
        Copy-Item -Path $CaddyfileExample -Destination $CaddyfileTarget
        Write-Host "  Created Caddyfile in apps/caddy/" -ForegroundColor Green
    }

    Write-Host "Setup complete! You can now run '.\stack up'." -ForegroundColor Cyan
}

function Resolve-TargetServices {
    if ($Group) {
        $TargetServices = @($Registry.GetEnumerator() | Where-Object { $_.Value.Group -eq $Group } | Select-Object -ExpandProperty Name)
        if ($TargetServices.Count -eq 0) {
            Write-Error "No services found in group '$Group'."
            exit 1
        }
    } else {
        $TargetServices = $Services
        if ($TargetServices.Count -eq 0) {
            if ($Command -in @("down", "status", "health")) {
                $TargetServices = @($Registry.Keys)
            } else {
                # Default to core group for 'up', 'restart' etc if no services specified
                $TargetServices = @($Registry.GetEnumerator() | Where-Object { $_.Value.Group -eq "core" } | Select-Object -ExpandProperty Name)
            }
        }
    }

    if ($Command -in @("up", "update", "pull", "test", "restart")) {
        # Always inject core group for these commands
        $coreServices = @($Registry.GetEnumerator() | Where-Object { $_.Value.Group -eq "core" } | Select-Object -ExpandProperty Name)
        $TargetServices = @($TargetServices + $coreServices | Select-Object -Unique)

        $FinalServices = Resolve-Dependencies $TargetServices
        if ($FinalServices.Count -gt $TargetServices.Count) {
            Write-Host "Automatically including dependencies..." -ForegroundColor Yellow
        }
        $TargetServices = $FinalServices
    }
    
    return $TargetServices
}

function Invoke-StackCommand {
    param(
        [string[]]$TargetServices,
        [string[]]$ComposeArgs,
        [string]$ProjectName
    )

    switch ($Command) {
        "up" {
            Write-Host "Starting services: $($TargetServices -join ', ')" -ForegroundColor Green
            docker compose $ComposeArgs up -d 2>&1 | ForEach-Object { Write-Host $_ }
    
            if ($TargetServices -contains "caddy") {
                Write-Host "Waiting for Caddy to generate root CA..."
                Start-Sleep -Seconds 3
                $certPath = Join-Path $ProjectRoot "caddy-root.crt"
                docker cp caddy:/data/caddy/pki/authorities/local/root.crt $certPath 2>$null
                if (Test-Path $certPath) {
                    try {
                        Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop | Out-Null
                        Write-Host "Successfully installed Caddy local CA certificate for secure HTTPS." -ForegroundColor Green
                    } catch {
                        Write-Host "Requesting Administrator privileges to trust Caddy's local HTTPS certificate..." -ForegroundColor Yellow
                        try {
                            $scriptBlock = "Import-Certificate -FilePath `"$certPath`" -CertStoreLocation Cert:\LocalMachine\Root"
                            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptBlock))
                            Start-Process powershell -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-EncodedCommand", $encoded -Verb RunAs -Wait
                            Write-Host "Successfully installed Caddy local CA certificate via UAC prompt." -ForegroundColor Green
                        } catch {
                            Write-Host "NOTE: To trust Caddy's local HTTPS certificate, run this as Administrator:" -ForegroundColor Yellow
                            Write-Host "Import-Certificate -FilePath .\caddy-root.crt -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor Yellow
                        }
                    }
                }
            }
            Write-Host "Dynamically attaching Caddy to required networks..."
            $prefix = $ProjectName
            $globalEnvPath = Join-Path $ProjectRoot "config/global.env"
            if (Test-Path $globalEnvPath) {
                Get-Content $globalEnvPath | ForEach-Object {
                    if ($_ -match "^PROJECT_NETWORK_PREFIX=(.*)") { $prefix = $Matches[1].Trim() }
                }
            }
            foreach ($service in $TargetServices) {
                if ($Registry.ContainsKey($service)) {
                    $group = $Registry[$service].Group
                    $netName = "$group-network"
                    $fullNetName = "${prefix}-${netName}"
                    docker network connect $fullNetName caddy 2>$null
                }
            }
            Write-Host "Reloading Caddy configuration gracefully..."
            docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>$null
        }
        "down" {
            Write-Host "Stopping and removing containers..." -ForegroundColor Green
            docker compose $ComposeArgs down 2>&1 | ForEach-Object { Write-Host $_ }
            
            $prefix = $ProjectName
            $globalEnvPath = Join-Path $ProjectRoot "config/global.env"
            if (Test-Path $globalEnvPath) {
                Get-Content $globalEnvPath | ForEach-Object {
                    if ($_ -match "^PROJECT_NETWORK_PREFIX=(.*)") { $prefix = $Matches[1].Trim() }
                }
            }
            
            # Clean up all dynamically created networks associated with this project
            docker network ls --format "{{.Name}}" | Where-Object { $_ -match "^${prefix}-" } | ForEach-Object {
                $net = $_
                Write-Host "Removing network $net..."
                $null = docker network rm $net 2>&1
            }
        }
        "stop" {
            Write-Host "Stopping containers..." -ForegroundColor Green
            if ($Services.Count -gt 0) {
                & docker compose $ComposeArgs stop $Services
            } else {
                & docker compose $ComposeArgs stop
            }
        }
        "restart" {
            Write-Host "Restarting services..." -ForegroundColor Green
            if ($Services.Count -gt 0) {
                & docker compose $ComposeArgs restart $Services
            } else {
                & docker compose $ComposeArgs restart
            }
        }
        "logs" {
            docker compose $ComposeArgs logs -f 2>&1 | ForEach-Object { Write-Host $_ }
        }
        "status" {
            docker compose $ComposeArgs ps 2>&1 | ForEach-Object { Write-Host $_ }
            
            $prefix = $ProjectName
            $globalEnvPath = Join-Path $ProjectRoot "config/global.env"
            if (Test-Path $globalEnvPath) {
                Get-Content $globalEnvPath | ForEach-Object {
                    if ($_ -match "^PROJECT_NETWORK_PREFIX=(.*)") { $prefix = $Matches[1].Trim() }
                }
            }
            
            Write-Host "`nOnline Networks:" -ForegroundColor Cyan
            docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>&1 | Where-Object { $_ -match "^NAME" -or $_ -match "^$prefix-" } | ForEach-Object { Write-Host $_ }
        }
        "health" {
            docker compose $ComposeArgs ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>&1 | ForEach-Object { Write-Host $_ }
        }
        "pull" {
            Write-Host "Pulling images..." -ForegroundColor Green
            docker compose $ComposeArgs pull 2>&1 | ForEach-Object { Write-Host $_ }
        }
        "update" {
            Write-Host "Updating services..." -ForegroundColor Green
            docker compose $ComposeArgs pull 2>&1 | ForEach-Object { Write-Host $_ }
            docker compose $ComposeArgs up -d 2>&1 | ForEach-Object { Write-Host $_ }
        }
        "config" {
            docker compose $ComposeArgs config 2>&1 | ForEach-Object { Write-Host $_ }
        }
        "test" {
            $testScript = Join-Path $ProjectRoot "scripts/Test-Services.ps1"
            if (Test-Path $testScript) {
                & $testScript -TargetServices $TargetServices -ProjectRoot $ProjectRoot -ComposeArgs $ComposeArgs
                
                $updateReadmeScript = Join-Path $ProjectRoot "scripts/Update-ReadmeTests.ps1"
                if (Test-Path $updateReadmeScript) {
                    & $updateReadmeScript -ProjectRoot $ProjectRoot
                }
            } else {
                Write-Error "Test script not found at $testScript"
            }
        }
        default {
            Write-Error "Unknown command: $Command"
            Show-Help
            exit 1
        }
    }
}
