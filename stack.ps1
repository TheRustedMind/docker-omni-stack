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

# Load Modules
. (Join-Path $ProjectRoot "scripts/Registry.ps1")
. (Join-Path $ProjectRoot "scripts/Stack-Helpers.ps1")
. (Join-Path $ProjectRoot "scripts/Stack-Commands.ps1")

Check-Docker

if ($Command -eq "help") {
    Show-Help
    exit 0
}

if ($Command -eq "services") {
    Show-Services
    exit 0
}

if ($Command -eq "groups") {
    Show-Groups
    exit 0
}

if ($Command -eq "setup") {
    Invoke-StackSetup -ProjectName $ProjectName
    exit 0
}

$TargetServices = Resolve-TargetServices

# Dynamically generate routing and networks for the target services
$routingScript = Join-Path $ProjectRoot "scripts/Configure-Routing.ps1"
if (Test-Path $routingScript) {
    & $routingScript -TargetServices $TargetServices -Registry $Registry -ProjectName $ProjectName
}

$ComposeArgs = Get-ComposeArgs -TargetServices $TargetServices

# If caddy-dynamic was generated, we must manually append it here, 
# or better yet, update Get-ComposeArgs in Stack-Helpers.ps1 to always include it.
# Actually, since Get-ComposeArgs is in a separate file, it's easier to append it here.
$dynamicCompose = Join-Path $ProjectRoot "compose/caddy-dynamic.yml"
if (Test-Path $dynamicCompose) {
    if (-not ($TargetServices -contains "caddy")) {
        $ComposeArgs += "--env-file"
        $ComposeArgs += Join-Path $ProjectRoot $Registry["caddy"].EnvFile
        $ComposeArgs += "-f"
        $ComposeArgs += Join-Path $ProjectRoot $Registry["caddy"].ComposeFile
    }
    $ComposeArgs += "-f"
    $ComposeArgs += $dynamicCompose
}

Invoke-StackCommand -TargetServices $TargetServices -ComposeArgs $ComposeArgs -ProjectName $ProjectName
