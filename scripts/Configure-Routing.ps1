param (
    [Parameter(Mandatory=$true)]
    [string[]]$TargetServices,

    [Parameter(Mandatory=$true)]
    [hashtable]$Registry,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName
)

$ProjectRoot = "c:\Docker"
$DynamicComposePath = Join-Path $ProjectRoot "compose/caddy-dynamic.yml"
$CaddyfilePath = Join-Path $ProjectRoot "apps/caddy/Caddyfile"

# 1. Determine Required Networks
$requiredNetworks = @("core-network")
foreach ($service in $TargetServices) {
    if ($Registry.ContainsKey($service)) {
        $group = $Registry[$service].Group
        $netName = "$group-network"
        if ($netName -notin $requiredNetworks) {
            $requiredNetworks += $netName
        }
    }
}

# 2. Generate caddy-dynamic.yml
$yaml = "networks:`n"

$prefix = $ProjectName
$globalEnvPath = Join-Path $ProjectRoot "config/global.env"
if (Test-Path $globalEnvPath) {
    Get-Content $globalEnvPath | ForEach-Object {
        if ($_ -match "^PROJECT_NETWORK_PREFIX=(.*)") { $prefix = $Matches[1].Trim() }
    }
}

foreach ($net in $requiredNetworks) {
    $yaml += "  ${net}:`n"
    $yaml += "    name: ${prefix}-${net}`n"
    $yaml += "    driver: bridge`n"
}

Set-Content -Path $DynamicComposePath -Value $yaml -NoNewline
Write-Host "Generated dynamic networks definitions: $($requiredNetworks -join ', ')" -ForegroundColor Cyan

# 3. Generate Caddyfile
$caddyfileContent = "# Dynamically generated Caddyfile by Configure-Routing.ps1`n`n"
$useAuth = $TargetServices -contains "authentik"

foreach ($service in $TargetServices) {
    if ($Registry.ContainsKey($service) -and $Registry[$service].ContainsKey("InternalPort")) {
        $port = $Registry[$service].InternalPort
        $isApi = $false
        if ($Registry[$service].ContainsKey("IsAPI")) {
            $isApi = $Registry[$service].IsAPI
        }
        
        # Skip Caddy itself
        if ($service -eq "caddy") { continue }
        
        $caddyfileContent += "${service}.localhost {`n"
        
        if ($isApi) {
            $caddyfileContent += "    # --- API_AUTH_BLOCK_START ---`n"
            $caddyfileContent += "    @invalid_key {`n"
            $caddyfileContent += "        not header Authorization `"Bearer {`$GLOBAL_API_KEY}`"`n"
            $caddyfileContent += "        not header X-API-Key `"{`$GLOBAL_API_KEY}`"`n"
            $caddyfileContent += "    }`n"
            $caddyfileContent += "    respond @invalid_key `"Unauthorized`" 401`n"
            $caddyfileContent += "    # --- API_AUTH_BLOCK_END ---`n`n"
        } elseif ($useAuth -and $service -ne "authentik") {
            $caddyfileContent += "    # --- AUTH_BLOCK_START ---`n"
            $caddyfileContent += "    forward_auth authentik:9000 {`n"
            $caddyfileContent += "        uri /outpost.goauthentik.io/auth/caddy`n"
            $caddyfileContent += "        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider`n"
            $caddyfileContent += "    }`n"
            $caddyfileContent += "    # --- AUTH_BLOCK_END ---`n`n"
        }
        
        $caddyfileContent += "    reverse_proxy ${service}:${port}`n"
        $caddyfileContent += "}`n`n"
    }
}

Set-Content -Path $CaddyfilePath -Value $caddyfileContent -NoNewline
Write-Host "Generated dynamic Caddyfile for UI services with Zero-Trust = $useAuth" -ForegroundColor Cyan
