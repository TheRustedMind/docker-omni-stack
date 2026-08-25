<#
.SYNOPSIS
Management script for the Project-Local Modular Docker Infrastructure.

.DESCRIPTION
Provides a consistent interface for managing Docker Compose services
in this modular infrastructure, including dependencies and groups.
#>

param(
    [Parameter(Position = 0, Mandatory = $true, HelpMessage="The command to execute")]
    [string]$Command,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Services,

    [string]$Group,

    [switch]$UseVolumes
)


$ProjectRoot = $PSScriptRoot
if (-not $ProjectRoot) {
    $ProjectRoot = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
if (-not $ProjectRoot) { $ProjectRoot = $PWD.Path }

$leaf = Split-Path $ProjectRoot -Leaf
if (-not $leaf) { $leaf = "docker-stack" }
$ProjectName = $leaf.ToLower() -replace '[^a-z0-9]', ''
# Service Registry
$Registry = @{
    "n8n" = @{
        ComposeFile = "compose/n8n.yml"
        EnvFile     = "config/n8n.env"
        Group       = "core"
        DependsOn   = @()
    }
    "cliproxyapi" = @{
        ComposeFile = "compose/cliproxyapi.yml"
        EnvFile     = "config/cliproxyapi.env"
        Group       = "core"
        DependsOn   = @()
    }
    "postgres" = @{
        ComposeFile = "compose/postgres.yml"
        EnvFile     = "config/postgres.env"
        Group       = "data"
        DependsOn   = @()
    }
    "redis" = @{
        ComposeFile = "compose/redis.yml"
        EnvFile     = "config/redis.env"
        Group       = "data"
        DependsOn   = @()
    }
    "minio" = @{
        ComposeFile = "compose/minio.yml"
        EnvFile     = "config/minio.env"
        Group       = "data"
        DependsOn   = @()
    }
    "qdrant" = @{
        ComposeFile = "compose/qdrant.yml"
        EnvFile     = "config/qdrant.env"
        Group       = "ai"
        DependsOn   = @()
    }
    "ollama" = @{
        ComposeFile = "compose/ollama.yml"
        EnvFile     = "config/ollama.env"
        Group       = "ai"
        DependsOn   = @()
    }
    "litellm" = @{
        ComposeFile = "compose/litellm.yml"
        EnvFile     = "config/litellm.env"
        Group       = "ai"
        DependsOn   = @("postgres")
    }
    "open-webui" = @{
        ComposeFile = "compose/open-webui.yml"
        EnvFile     = "config/open-webui.env"
        Group       = "ai-apps"
        DependsOn   = @("ollama")
    }
    "flowise" = @{
        ComposeFile = "compose/flowise.yml"
        EnvFile     = "config/flowise.env"
        Group       = "ai-apps"
        DependsOn   = @("postgres")
    }
    "dify" = @{
        ComposeFile = "compose/dify.yml"
        EnvFile     = "config/dify.env"
        Group       = "ai-apps"
        DependsOn   = @("postgres", "redis")
    }
    "uptime-kuma" = @{
        ComposeFile = "compose/uptime-kuma.yml"
        EnvFile     = "config/uptime-kuma.env"
        Group       = "monitoring"
        DependsOn   = @()
    }
    "prometheus" = @{
        ComposeFile = "compose/prometheus.yml"
        EnvFile     = "config/prometheus.env"
        Group       = "monitoring"
        DependsOn   = @()
    }
    "grafana" = @{
        ComposeFile = "compose/grafana.yml"
        EnvFile     = "config/grafana.env"
        Group       = "monitoring"
        DependsOn   = @("prometheus")
    }
    "caddy" = @{
        ComposeFile = "compose/caddy.yml"
        EnvFile     = "config/caddy.env"
        Group       = "networking"
        DependsOn   = @()
    }
    "authentik" = @{
        ComposeFile = "compose/authentik.yml"
        EnvFile     = "config/authentik.env"
        Group       = "auth"
        DependsOn   = @("postgres", "redis")
    }
    "rabbitmq" = @{
        ComposeFile = "compose/rabbitmq.yml"
        EnvFile     = "config/rabbitmq.env"
        Group       = "optional"
        DependsOn   = @()
    }
    "gitea" = @{
        ComposeFile = "compose/gitea.yml"
        EnvFile     = "config/gitea.env"
        Group       = "development"
        DependsOn   = @("postgres")
    }
    "tika" = @{
        ComposeFile = "compose/tika.yml"
        EnvFile     = "config/tika.env"
        Group       = "processing"
        DependsOn   = @()
    }
    "gotenberg" = @{
        ComposeFile = "compose/gotenberg.yml"
        EnvFile     = "config/gotenberg.env"
        Group       = "processing"
        DependsOn   = @()
    }
    "hoppscotch" = @{
        ComposeFile = "compose/hoppscotch.yml"
        EnvFile     = "config/hoppscotch.env"
        Group       = "tools"
        DependsOn   = @("postgres")
    }
}

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

    $BaseCompose = Join-Path $ProjectRoot "compose/base.yml"
    if (Test-Path $BaseCompose) {
        $Args += "-f"
        $Args += $BaseCompose
    } else {
        Write-Error "Missing base compose file: $BaseCompose"
        exit 1
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
        $env:VOL_POSTGRES_DATA = "postgres_data"
        $env:VOL_PROMETHEUS_DATA = "prometheus_data"
        $env:VOL_QDRANT_DATA = "qdrant_data"
        $env:VOL_RABBITMQ_DATA = "rabbitmq_data"
        $env:VOL_REDIS_DATA = "redis_data"
        $env:VOL_UPTIMEKUMA_DATA = "uptimekuma_data"
    } else {
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
        $env:VOL_POSTGRES_DATA = $null
        $env:VOL_PROMETHEUS_DATA = $null
        $env:VOL_QDRANT_DATA = $null
        $env:VOL_RABBITMQ_DATA = $null
        $env:VOL_REDIS_DATA = $null
        $env:VOL_UPTIMEKUMA_DATA = $null
    }

    return $Args
}

Check-Docker

if ($Command -eq "help") {
    Show-Help
    exit 0
}
if ($Command -eq "services") {
    Write-Host "Registered Services:"
    $Registry.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $deps = if ($_.Value.DependsOn.Count -gt 0) { $_.Value.DependsOn -join ", " } else { "None" }
        Write-Host "- $($_.Name) (Group: $($_.Value.Group)) [Dependencies: $deps]"
    }
    exit 0
}
if ($Command -eq "groups") {
    Write-Host "Registered Groups:"
    $Groups = $Registry.Values.Group | Select-Object -Unique | Sort-Object
    foreach ($grp in $Groups) {
        $svcCount = @($Registry.GetEnumerator() | Where-Object { $_.Value.Group -eq $grp }).Count
        Write-Host "- $grp ($svcCount services)"
    }
    exit 0
}

if ($Command -eq "setup") {
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
        Set-Content -Path $GlobalEnv -Value "PROJECT_DATA_DIR=../data`nPROJECT_APPS_DIR=../apps`nUSE_DOCKER_VOLUMES=$useVolStr"
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



    Write-Host "Setup complete! You can now run '.\stack up'." -ForegroundColor Cyan
    exit 0
}

# Determine target services
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

if ($Command -in @("up", "update", "pull")) {
    $FinalServices = Resolve-Dependencies $TargetServices
    if ($FinalServices.Count -gt $TargetServices.Count) {
        Write-Host "Automatically including dependencies..." -ForegroundColor Yellow
    }
    $TargetServices = $FinalServices
}

$ComposeArgs = Get-ComposeArgs -TargetServices $TargetServices

switch ($Command) {
    "up" {
        Write-Host "Starting services: $($TargetServices -join ', ')" -ForegroundColor Green
        docker compose $ComposeArgs up -d 2>&1 | ForEach-Object { Write-Host $_ }
    }
    "down" {
        Write-Host "Stopping and removing containers..." -ForegroundColor Green
        docker compose $ComposeArgs down 2>&1 | ForEach-Object { Write-Host $_ }
        
        # Explicitly forcefully delete the network just in case it got stuck or was manually created
        $netName = "project-network"
        $globalEnvPath = Join-Path $ProjectRoot "config/global.env"
        if (Test-Path $globalEnvPath) {
            Get-Content $globalEnvPath | ForEach-Object {
                if ($_ -match "^PROJECT_NETWORK=(.*)") { $netName = $Matches[1].Trim() }
            }
        }
        Write-Host "Ensuring network '$netName' is removed..." -ForegroundColor Green
        $null = docker network rm $netName 2>&1
    }
    "stop" {
        Write-Host "Stopping containers..." -ForegroundColor Green
        docker compose $ComposeArgs stop 2>&1 | ForEach-Object { Write-Host $_ }
    }
    "restart" {
        Write-Host "Restarting services..." -ForegroundColor Green
        docker compose $ComposeArgs restart 2>&1 | ForEach-Object { Write-Host $_ }
    }
    "logs" {
        docker compose $ComposeArgs logs -f 2>&1 | ForEach-Object { Write-Host $_ }
    }
    "status" {
        docker compose $ComposeArgs ps 2>&1 | ForEach-Object { Write-Host $_ }
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
    default {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
