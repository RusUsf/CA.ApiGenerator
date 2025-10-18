Write-Host "=== FULL PIPELINE ORCHESTRATOR ===" -ForegroundColor Cyan
Write-Host ""

# Save starting directory
$startDir = Get-Location

# Find scripts
$setupScript = Get-ChildItem -Path $PSScriptRoot -Filter "Clean_Architecture_Master*.ps1" | Select-Object -First 1
$createCodeGenScript = Get-ChildItem -Path $PSScriptRoot -Filter "Create-CodeGeneratorDev*.ps1" | Select-Object -First 1
$copyScript = Get-ChildItem -Path $PSScriptRoot -Filter "Copy-CodeGenToSolution*.ps1" | Select-Object -First 1



# Check if solution exists
$existingSolution = Get-ChildItem -Filter "*.sln" -Recurse | 
    Where-Object { $_.Directory.Name -notmatch "CodeGeneratorDev" } | 
    Select-Object -First 1

if (-not $existingSolution) {
    Write-Host "Step 1: Running Main Setup..." -ForegroundColor Yellow
    & "$PSScriptRoot\$($setupScript.Name)"
    Set-Location $startDir
    
    Write-Host ""
    Write-Host "Step 2: Creating CodeGeneratorDev..." -ForegroundColor Yellow
    & "$PSScriptRoot\$($createCodeGenScript.Name)"
    Set-Location $startDir
}
else {
    Write-Host "Step 1-2: Solution exists, skipping setup" -ForegroundColor Green
}

# Re-find solution (in case just created)
$solution = Get-ChildItem -Filter "*.sln" -Recurse | 
    Where-Object { $_.Directory.Name -notmatch "CodeGeneratorDev" } | 
    Select-Object -First 1
$solutionDir = $solution.Directory.FullName
$projectName = $solution.BaseName

Write-Host ""
Write-Host "Step 3: Copying CodeGen to solution..." -ForegroundColor Yellow
& "$PSScriptRoot\$($copyScript.Name)"
Set-Location $startDir

Write-Host ""
Write-Host ""
Write-Host "Step 4: Running Code Generator..." -ForegroundColor Yellow

# Validate project name is set
if ([string]::IsNullOrWhiteSpace($projectName)) {
    Write-Host "Γ£ù ERROR: Project name is empty or not set" -ForegroundColor Red
    exit 1
}

# Look for the specific DLL that matches the project name
$expectedDllName = "$projectName.Domain.dll"
$domainDll = Get-ChildItem -Path $solutionDir -Filter $expectedDllName -Recurse |
    Where-Object { $_.FullName -match "artifacts.*bin.*Domain.*release" } |
    Select-Object -First 1

# Validate DLL was found
if (-not $domainDll) {
    Write-Host "Γ£ù ERROR: Domain DLL not found!" -ForegroundColor Red
    Write-Host "  Expected: $expectedDllName" -ForegroundColor Yellow
    Write-Host "  Search path: $solutionDir" -ForegroundColor Yellow
    Write-Host "  Project name: $projectName" -ForegroundColor Yellow
    
    # List what DLLs were found for debugging
    $foundDlls = Get-ChildItem -Path $solutionDir -Filter "*Domain.dll" -Recurse
    if ($foundDlls) {
        Write-Host "  Found DLLs:" -ForegroundColor Yellow
        foreach ($dll in $foundDlls) {
            Write-Host "    - $($dll.Name)" -ForegroundColor Gray
        }
    }
    exit 1
}

Write-Host "✓ Found Domain DLL: $($domainDll.Name)" -ForegroundColor Green

Push-Location (Join-Path $solutionDir "src\CodeGeneratorDev")
dotnet run -- $domainDll.FullName $solutionDir $projectName
Pop-Location

Write-Host ""
Write-Host "Step 5: Starting Web project..." -ForegroundColor Yellow
Push-Location (Join-Path $solutionDir "src\Web")
$shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
Start-Process $shell -ArgumentList "-NoProfile", "-NoExit", "-Command", "dotnet run"
Pop-Location


Write-Host ""
Write-Host "=== PIPELINE COMPLETE ===" -ForegroundColor Green
Write-Host "Web project running in separate window"
Write-Host ""
Write-Host "Access the API at: https://localhost:5001/swagger" -ForegroundColor Cyan
Write-Host ""
Write-Host "Solution directory is now unlocked and can be deleted"


# =============================================================================
# STEP 6: CLEANUP TEMPORARY FILES
# =============================================================================
Write-Host ""
Write-Host "=== CLEANING UP TEMPORARY FILES ===" -ForegroundColor Cyan

# Clean up TempScaffold directory
$tempScaffoldDirs = Get-ChildItem -Path $startDir -Directory -Filter "TempScaffold*" -ErrorAction SilentlyContinue

if ($tempScaffoldDirs) {
    foreach ($dir in $tempScaffoldDirs) {
        try {
            Remove-Item $dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Removed $($dir.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not remove $($dir.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "  ℹ TempScaffold folders not found (already cleaned or not created)" -ForegroundColor Gray
}

# Clean up standalone CodeGeneratorDev directory (preserves the copy inside solution)
$standaloneCodeGen = Join-Path $startDir "CodeGeneratorDev"
if (Test-Path $standaloneCodeGen) {
    # Verify this is the standalone version, not one inside a solution
    $parentDir = Split-Path -Parent $standaloneCodeGen
    $isSolutionCopy = Test-Path (Join-Path $parentDir "*.sln")
    
    if (-not $isSolutionCopy) {
        try {
            Remove-Item $standaloneCodeGen -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Removed standalone CodeGeneratorDev folder" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not remove CodeGeneratorDev: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ℹ CodeGeneratorDev is part of solution, preserving" -ForegroundColor Gray
    }
}
else {
    Write-Host "  ℹ Standalone CodeGeneratorDev not found (already cleaned or not created)" -ForegroundColor Gray
}

Write-Host "  ✓ Cleanup complete" -ForegroundColor Green
Write-Host ""

# =============================================================================
# STEP 7: DISPLAY FINAL SUMMARY AND NEXT STEPS
# =============================================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    PIPELINE COMPLETE!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Display solution location and name
$solutionLocation = (Get-Location).Path
$solutionName = (Get-ChildItem -Filter "*.sln" | Select-Object -First 1).BaseName

Write-Host "=== SOLUTION DETAILS ===" -ForegroundColor Cyan
Write-Host "  Solution Name:    $solutionName" -ForegroundColor White
Write-Host "  Solution Path:    $solutionLocation" -ForegroundColor White
Write-Host "  Database:         $databaseName" -ForegroundColor White
Write-Host "  Provider:         $databaseProvider" -ForegroundColor White
Write-Host ""

# Display API access information
Write-Host "=== ACCESS YOUR API ===" -ForegroundColor Cyan
Write-Host "  The Web project is running in a separate window." -ForegroundColor White
Write-Host ""
Write-Host "  📍 Swagger UI:     " -NoNewline -ForegroundColor Yellow
Write-Host "https://localhost:5001/swagger/index.html" -ForegroundColor Green
Write-Host ""
Write-Host "  Alternative ports (if 5001 is in use):" -ForegroundColor Gray
Write-Host "    • https://localhost:7xxx/swagger/index.html" -ForegroundColor Gray
Write-Host "    • http://localhost:5000/swagger/index.html" -ForegroundColor Gray
Write-Host ""
Write-Host "  💡 TIP: Check the Web project console window for actual port numbers" -ForegroundColor Yellow
Write-Host ""

# Display next steps
Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "  1. Open Swagger UI in your browser (link above)" -ForegroundColor White
Write-Host "  2. Test the auto-generated API endpoints" -ForegroundColor White
Write-Host "  3. Open solution in Visual Studio:" -ForegroundColor White
Write-Host "     cd $solutionLocation" -ForegroundColor Gray
Write-Host "     start $solutionName.sln" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Review generated code in:" -ForegroundColor White
Write-Host "     • src/Domain/Entities/        (Your domain models)" -ForegroundColor Gray
Write-Host "     • src/Application/            (CQRS commands & queries)" -ForegroundColor Gray
Write-Host "     • src/Web/Controllers/        (API endpoints)" -ForegroundColor Gray
Write-Host ""

# Display useful commands
Write-Host "=== USEFUL COMMANDS ===" -ForegroundColor Cyan
Write-Host "  Navigate to solution:" -ForegroundColor White
Write-Host "    cd $solutionLocation" -ForegroundColor Gray
Write-Host ""
Write-Host "  Run application manually:" -ForegroundColor White
Write-Host "    cd src\Web" -ForegroundColor Gray
Write-Host "    dotnet run" -ForegroundColor Gray
Write-Host ""
Write-Host "  Run tests:" -ForegroundColor White
Write-Host "    dotnet test" -ForegroundColor Gray
Write-Host ""
Write-Host "  Generate new entity endpoints:" -ForegroundColor White
Write-Host "    cd src\CodeGeneratorDev" -ForegroundColor Gray
Write-Host "    dotnet run" -ForegroundColor Gray
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🎉 Your Clean Architecture API is ready for development! 🎉  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""