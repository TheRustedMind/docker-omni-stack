function Show-Help {
    Write-Host "Usage: .\stack <command> [services] [-Group <group>]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  setup    First-time installation (creates envs, folders, networks)"
    Write-Host "  up       Start services (default: core group)"
    Write-Host "  down     Stop and remove containers (preserves volumes)"
    Write-Host "  stop     Stop containers without removing them"
    Write-Host "  restart  Restart services"
    Write-Host "  logs     View logs"
    Write-Host "  status   Show container status"
    Write-Host "  pull     Pull images"
    Write-Host "  update   Pull images and recreate containers"
    Write-Host "  config   Validate Docker Compose configuration"
    Write-Host "  services List all registered services"
    Write-Host "  groups   List all registered groups"
    Write-Host "  health   Show health status of running containers"
    Write-Host "  help     Show this help message"
}

function Check-Docker {
    try {
        $null = docker --version
        $null = docker compose version
        $null = docker info
    } catch {
        Write-Error "Docker is not available or Docker Desktop is not running."
        exit 1
    }
}

function Resolve-Dependencies([string[]]$TargetServices) {
    $Resolved = [System.Collections.Generic.HashSet[string]]::new()
    $Queue = [System.Collections.Generic.Queue[string]]::new()

    foreach ($Svc in $TargetServices) {
        $Queue.Enqueue($Svc)
    }

    while ($Queue.Count -gt 0) {
        $Current = $Queue.Dequeue()
        if (-not $Resolved.Contains($Current)) {
            $null = $Resolved.Add($Current)
            if ($Registry.ContainsKey($Current)) {
                foreach ($Dep in $Registry[$Current].DependsOn) {
                    if (-not $Resolved.Contains($Dep)) {
                        $Queue.Enqueue($Dep)
                    }
                }
            }
        }
    }
    return [string[]]($Resolved)
}

function Get-ComposeArgs {
    param([string[]]$TargetServices)
    
    $Args = @("--project-name", $ProjectName)
    
    $GlobalEnv = Join-Path $ProjectRoot "config/global.env"
    if (Test-Path $GlobalEnv) {
        $Args += "--env-file"
        $Args += $GlobalEnv
    } else {
        Write-Warning "Global environment file not found: $GlobalEnv"
    }


    foreach ($Service in $TargetServices) {
        if (-not $Registry.ContainsKey($Service)) {
            Write-Error "Unknown service '$Service'."
            exit 1
        }
        
        $SvcEnv = Join-Path $ProjectRoot $Registry[$Service].EnvFile
        if (Test-Path $SvcEnv) {
            $Args += "--env-file"
            $Args += $SvcEnv
        } else {
            Write-Error "Missing environment file for '$Service': $SvcEnv"
            exit 1
        }
    }

    foreach ($Service in $TargetServices) {
        $SvcCompose = Join-Path $ProjectRoot $Registry[$Service].ComposeFile
        if (Test-Path $SvcCompose) {
            $Args += "-f"
            $Args += $SvcCompose
        } else {
            Write-Error "Missing compose file for '$Service': $SvcCompose"
            exit 1
        }
    }

    $UseDockerVolumes = $false
    if (Test-Path $GlobalEnv) {
        Get-Content $GlobalEnv | ForEach-Object {
            if ($_ -match "^USE_DOCKER_VOLUMES=(true|1|yes)") { $UseDockerVolumes = $true }
        }
    }

    if ($UseDockerVolumes) {
        $env:VOL_AUTHENTIK_CERTS = "authentik_certs"
        $env:VOL_AUTHENTIK_MEDIA = "authentik_media"
        $env:VOL_AUTHENTIK_TEMPLATES = "authentik_templates"
        $env:VOL_CADDY_DATA = "caddy_data"
        $env:VOL_CADDY_CONFIG = "caddy_config"
        $env:VOL_CLIPROXYAPI_AUTH = "cliproxyapi_auth"
        $env:VOL_DIFY_STORAGE = "dify_storage"
        $env:VOL_FLOWISE_DATA = "flowise_data"
        $env:VOL_GITEA_DATA = "gitea_data"
        $env:VOL_GRAFANA_DATA = "grafana_data"
        $env:VOL_MINIO_DATA = "minio_data"
        $env:VOL_N8N_DATA = "n8n_data"
        $env:VOL_OLLAMA_DATA = "ollama_data"
        $env:VOL_OPENWEBUI_DATA = "openwebui_data"
        $env:VOL_PGADMIN_DATA = "pgadmin_data"
        $env:VOL_POSTGRES_DATA = "postgres_data"
        $env:VOL_PROMETHEUS_DATA = "prometheus_data"
        $env:VOL_QDRANT_DATA = "qdrant_data"
        $env:VOL_RABBITMQ_DATA = "rabbitmq_data"
        $env:VOL_REDIS_DATA = "redis_data"
        $env:VOL_UPTIMEKUMA_DATA = "uptimekuma_data"
    } else {
        $env:VOL_AUTHENTIK_CERTS = $null
        $env:VOL_AUTHENTIK_MEDIA = $null
        $env:VOL_AUTHENTIK_TEMPLATES = $null
        $env:VOL_CADDY_DATA = $null
        $env:VOL_CADDY_CONFIG = $null
        $env:VOL_CLIPROXYAPI_AUTH = $null
        $env:VOL_DIFY_STORAGE = $null
        $env:VOL_FLOWISE_DATA = $null
        $env:VOL_GITEA_DATA = $null
        $env:VOL_GRAFANA_DATA = $null
        $env:VOL_MINIO_DATA = $null
        $env:VOL_N8N_DATA = $null
        $env:VOL_OLLAMA_DATA = $null
        $env:VOL_OPENWEBUI_DATA = $null
        $env:VOL_PGADMIN_DATA = $null
        $env:VOL_POSTGRES_DATA = $null
        $env:VOL_PROMETHEUS_DATA = $null
        $env:VOL_QDRANT_DATA = $null
        $env:VOL_RABBITMQ_DATA = $null
        $env:VOL_REDIS_DATA = $null
        $env:VOL_UPTIMEKUMA_DATA = $null
    }

    return $Args
}
