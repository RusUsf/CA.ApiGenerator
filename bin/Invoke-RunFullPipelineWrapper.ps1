<#
.SYNOPSIS
    Wrapper for Run-FullPipeline.ps1 that supports module parameters
.DESCRIPTION
    Passes module parameters to the original script via environment variables.
    If no module parameters are set, the original script prompts interactively.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ScriptPath = (Join-Path $PSScriptRoot "Run-FullPipeline.ps1")
)

Write-Host "=== Run-FullPipeline Wrapper ===" -ForegroundColor Cyan

# Pass module parameters via environment variables
if ($global:CAConnectionString) {
    $env:CA_CONNECTION_STRING = $global:CAConnectionString
    Write-Host "Using connection string from module" -ForegroundColor Green
}

if ($global:CAProjectName) {
    $env:CA_PROJECT_NAME = $global:CAProjectName
    Write-Host "Using project name from module: $global:CAProjectName" -ForegroundColor Green
}

if ($global:CAInteractive) {
    $env:CA_INTERACTIVE = $global:CAInteractive
}

# Verify original script exists
if (-not (Test-Path $ScriptPath)) {
    throw "Run-FullPipeline.ps1 not found at: $ScriptPath"
}

# Invoke the ORIGINAL script unchanged
& $ScriptPath

# Clean up environment variables
Remove-Item env:CA_CONNECTION_STRING -ErrorAction SilentlyContinue
Remove-Item env:CA_PROJECT_NAME -ErrorAction SilentlyContinue
Remove-Item env:CA_INTERACTIVE -ErrorAction SilentlyContinue

Write-Host "=== Wrapper Complete ===" -ForegroundColor Cyan
