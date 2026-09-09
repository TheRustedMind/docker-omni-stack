# Service Registry

function ConvertTo-Hashtable {
    param([Parameter(ValueFromPipeline)] $InputObject)
    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
            $hash = @{}
            foreach ($property in $InputObject.psobject.properties) {
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }
            return $hash
        }
        elseif ($InputObject -is [System.Array]) {
            $arr = @()
            foreach ($item in $InputObject) {
                $arr += ,(ConvertTo-Hashtable $item)
            }
            return ,$arr
        }
        else {
            return $InputObject
        }
    }
}

$RegistryJsonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "registry.json"
if (Test-Path $RegistryJsonPath) {
    $jsonObj = Get-Content -Raw $RegistryJsonPath | ConvertFrom-Json
    $Registry = ConvertTo-Hashtable $jsonObj
} else {
    Write-Error "registry.json not found at $RegistryJsonPath"
}
