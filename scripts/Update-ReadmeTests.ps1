param (
    [string]$ProjectRoot = "c:\Docker"
)

$JsonPath = Join-Path $ProjectRoot "test-results.json"
$ReadmePath = Join-Path $ProjectRoot "README.md"

if (-not (Test-Path $JsonPath)) {
    Write-Warning "test-results.json not found."
    exit 1
}

$results = Get-Content $JsonPath | ConvertFrom-Json

$table = @()
$table += "| Service | Status | Last Tested | Has Custom Test |"
$table += "|---------|--------|-------------|-----------------|"

foreach ($service in $results.PSObject.Properties.Name | Sort-Object) {
    $info = $results.$service
    
    $statusIcon = if ($info.Status -eq "Pass") { "Pass" } elseif ($info.Status -eq "Fail") { "Fail" } else { "Unknown" }
    $customTest = if ($info.HasCustomTest) { "Yes" } else { "No" }
    
    $table += "| **$service** | $statusIcon | $($info.LastTested) | $customTest |"
}

$tableString = $table -join "`r`n"

$readmeContent = Get-Content $ReadmePath -Raw
$pattern = '(?s)<!-- TEST_RESULTS_START -->.*?<!-- TEST_RESULTS_END -->'
$replacement = "<!-- TEST_RESULTS_START -->`r`n$tableString`r`n<!-- TEST_RESULTS_END -->"

$newReadme = $readmeContent -replace $pattern, $replacement
Set-Content -Path $ReadmePath -Value $newReadme -NoNewline

Write-Host "Updated README.md with latest test results." -ForegroundColor Green
