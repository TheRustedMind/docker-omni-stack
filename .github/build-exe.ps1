$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SourceStack = Join-Path $ProjectRoot "stack.ps1"
$TargetStack = Join-Path $ProjectRoot "stack-monolithic.ps1"

Write-Host "Reading stack.ps1..."
$lines = Get-Content $SourceStack

$outputLines = @()
$skipLines = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($skipLines -gt 0) {
        $skipLines--
        continue
    }

    $line = $lines[$i]

    # Handle dot-sourced files
    if ($line -match '^\s*\.\s*\(Join-Path \$ProjectRoot "(scripts/[^"]+)"\)') {
        $scriptPath = Join-Path $ProjectRoot $Matches[1]
        Write-Host "Inlining dot-sourced script: $($Matches[1])"
        $outputLines += "# --- INLINED: $($Matches[1]) ---"
        $outputLines += Get-Content $scriptPath
        $outputLines += "# --- END INLINE: $($Matches[1]) ---"
        continue
    }

    # Handle Configure-Routing invocation block
    if ($line -match '^\$routingScript = Join-Path \$ProjectRoot "scripts/Configure-Routing.ps1"') {
        Write-Host "Inlining Configure-Routing.ps1..."
        $routingPath = Join-Path $ProjectRoot "scripts/Configure-Routing.ps1"
        $routingContent = Get-Content $routingPath | Out-String
        
        $outputLines += "`$ConfigureRouting = {"
        $outputLines += $routingContent
        $outputLines += "}"
        $outputLines += "& `$ConfigureRouting -TargetServices `$TargetServices -Registry `$Registry -ProjectName `$ProjectName"
        
        # We know the original block spans 4 lines:
        # $routingScript = Join-Path $ProjectRoot "scripts/Configure-Routing.ps1"
        # if (Test-Path $routingScript) {
        #     & $routingScript -TargetServices $TargetServices -Registry $Registry -ProjectName $ProjectName
        # }
        $skipLines = 3
        continue
    }

    $outputLines += $line
}

$TargetStackText = $outputLines -join "`r`n"

Write-Host "Inlining Test-Services.ps1..."
$TestScriptContent = Get-Content (Join-Path $ProjectRoot "scripts/Test-Services.ps1") | Out-String
$TargetStackText = $TargetStackText -replace '(?s)\$testScript = Join-Path \$ProjectRoot "scripts/Test-Services.ps1".*?& \$testScript -TargetServices \$TargetServices -ProjectRoot \$ProjectRoot -ComposeArgs \$ComposeArgs', "`$TestServicesBlock = {`r`n$TestScriptContent`r`n}`r`n                & `$TestServicesBlock -TargetServices `$TargetServices -ProjectRoot `$ProjectRoot -ComposeArgs `$ComposeArgs"

Write-Host "Inlining Update-ReadmeTests.ps1..."
$UpdateScriptContent = Get-Content (Join-Path $ProjectRoot "scripts/Update-ReadmeTests.ps1") | Out-String
$TargetStackText = $TargetStackText -replace '(?s)\$updateReadmeScript = Join-Path \$ProjectRoot "scripts/Update-ReadmeTests.ps1".*?& \$updateReadmeScript -ProjectRoot \$ProjectRoot', "`$UpdateReadmeBlock = {`r`n$UpdateScriptContent`r`n}`r`n                & `$UpdateReadmeBlock -ProjectRoot `$ProjectRoot"

Write-Host "Writing stack-monolithic.ps1..."
Set-Content -Path $TargetStack -Value $TargetStackText
Write-Host "Compilation preparation complete!"
