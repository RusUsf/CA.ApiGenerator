# =============================================================================
# COPY CODEGENERATORDEV INTO EXISTING SOLUTION - DEVELOPMENT HELPER
# =============================================================================
# PURPOSE: Copy standalone CodeGeneratorDev into ANY existing CA solution
# USAGE: Run from directory containing the target solution folder
# NOTE: Keeps original CodeGeneratorDev intact for reuse with other projects
# =============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$TargetSolutionPath,
    
    [Parameter(Mandatory = $false)]
    [string]$CodeGenSourcePath
)

Write-Host "=== COPYING CODEGENERATORDEV INTO SOLUTION ===" -ForegroundColor Cyan
Write-Host ""

# Auto-detect CodeGeneratorDev source if not provided
if ([string]::IsNullOrWhiteSpace($CodeGenSourcePath)) {
    Write-Host "Auto-detecting CodeGeneratorDev location..." -ForegroundColor White
    
    if (Test-Path "CodeGeneratorDev\CodeGeneratorDev\CodeGeneratorDev.csproj") {
        $CodeGenSourcePath = "CodeGeneratorDev"
        Write-Host "  ✓ Found at: $CodeGenSourcePath" -ForegroundColor Green
    }
    elseif (Test-Path "..\CodeGeneratorDev\CodeGeneratorDev\CodeGeneratorDev.csproj") {
        $CodeGenSourcePath = "..\CodeGeneratorDev"
        Write-Host "  ✓ Found at: $CodeGenSourcePath" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Cannot find CodeGeneratorDev folder" -ForegroundColor Red
        Write-Host "  Expected: CodeGeneratorDev\CodeGeneratorDev\CodeGeneratorDev.csproj" -ForegroundColor Yellow
        exit 1
    }
}

# Auto-detect target solution if not provided
if ([string]::IsNullOrWhiteSpace($TargetSolutionPath)) {
    Write-Host "Auto-detecting target solution..." -ForegroundColor White
    
    $solutions = Get-ChildItem -Path . -Filter "*.sln" -File | 
    Where-Object { $_.Directory.Name -ne "CodeGeneratorDev" }
    
    if ($solutions.Count -eq 1) {
        $TargetSolutionPath = $solutions[0].Directory.FullName
        Write-Host "  ✓ Found: $($solutions[0].BaseName)" -ForegroundColor Green
    }
    elseif ($solutions.Count -gt 1) {
        Write-Host "  Multiple solutions found. Select one:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $solutions.Count; $i++) {
            Write-Host "  [$i] $($solutions[$i].Name)" -ForegroundColor White
        }
        $selection = Read-Host "Enter number"
        if ($selection -match '^\d+$' -and [int]$selection -lt $solutions.Count) {
            $TargetSolutionPath = $solutions[[int]$selection].Directory.FullName
        }
        else {
            Write-Host "Invalid selection" -ForegroundColor Red
            exit 1
        }
    }
    else {
        # Look for directories containing .sln files (exclude CodeGeneratorDev)
        $apiDirs = Get-ChildItem -Directory | Where-Object { 
            $_.Name -ne "CodeGeneratorDev" -and
            (Get-ChildItem -Path $_.FullName -Filter "*.sln" -File).Count -gt 0
        }
    
        if ($apiDirs.Count -eq 1) {
            $TargetSolutionPath = $apiDirs[0].FullName
            Write-Host "  ✓ Found: $($apiDirs[0].Name)" -ForegroundColor Green
        }
        elseif ($apiDirs.Count -gt 1) {
            Write-Host "  Multiple solutions found. Select one:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $apiDirs.Count; $i++) {
                Write-Host "  [$i] $($apiDirs[$i].Name)" -ForegroundColor White
            }
            $selection = Read-Host "Enter number"
            if ($selection -match '^\d+$' -and [int]$selection -lt $apiDirs.Count) {
                $TargetSolutionPath = $apiDirs[[int]$selection].FullName
            }
            else {
                Write-Host "Invalid selection" -ForegroundColor Red
                exit 1
            }
        }
        else {
            Write-Host "  ✗ No solution found in subdirectories" -ForegroundColor Red
            Write-Host "  ℹ Looking for any folder (except CodeGeneratorDev) containing a .sln file" -ForegroundColor Gray
            exit 1
        }
    }
}

# Validate paths
if (-not (Test-Path $TargetSolutionPath)) {
    Write-Host "ERROR: Target solution not found: $TargetSolutionPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "$CodeGenSourcePath\CodeGeneratorDev\CodeGeneratorDev.csproj")) {
    Write-Host "ERROR: CodeGeneratorDev project not found at: $CodeGenSourcePath\CodeGeneratorDev" -ForegroundColor Red
    exit 1
}

$solutionFile = Get-ChildItem -Path $TargetSolutionPath -Filter "*.sln" | Select-Object -First 1
if (-not $solutionFile) {
    Write-Host "ERROR: No .sln file found in $TargetSolutionPath" -ForegroundColor Red
    exit 1
}

$projectName = $solutionFile.BaseName
Write-Host ""
Write-Host "Target solution: $projectName" -ForegroundColor White
Write-Host "Location: $TargetSolutionPath" -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "Step 1: Copying CodeGeneratorDev project..." -ForegroundColor White
    
    $targetCodeGenPath = Join-Path $TargetSolutionPath "src\CodeGeneratorDev"
    
    if (Test-Path $targetCodeGenPath) {
        Write-Host "  CodeGeneratorDev already exists in this solution" -ForegroundColor Yellow
        $overwrite = Read-Host "  Overwrite? (y/n)"
        if ($overwrite -ne 'y') {
            Write-Host "Cancelled" -ForegroundColor Yellow
            exit 0
        }
        Remove-Item -Path $targetCodeGenPath -Recurse -Force
    }
    
    $srcPath = Join-Path $TargetSolutionPath "src"
    if (-not (Test-Path $srcPath)) {
        New-Item -ItemType Directory -Path $srcPath -Force | Out-Null
    }
    
    Copy-Item -Path "$CodeGenSourcePath\CodeGeneratorDev" -Destination $srcPath -Recurse -Force
    Write-Host "  ✓ Copied to src\CodeGeneratorDev (original preserved)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Step 2: Adding to solution..." -ForegroundColor White
    
    Push-Location $TargetSolutionPath
    
    $addResult = dotnet sln add "src\CodeGeneratorDev\CodeGeneratorDev.csproj" 2>&1
    if ($LASTEXITCODE -eq 0 -or $addResult -match "already in the solution") {
        Write-Host "  ✓ Added to solution" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Add may have failed: $addResult" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Step 3: Adding project references..." -ForegroundColor White
    
    $projectsToReference = Get-ChildItem -Path "src" -Filter "*.csproj" -Recurse | 
    Where-Object { $_.Directory.Name -ne "CodeGeneratorDev" } |
    Where-Object { $_.Name -notlike "*Tests*" }
    
    if ($projectsToReference.Count -eq 0) {
        Write-Host "  ⚠ No projects found to reference" -ForegroundColor Yellow
    }
    else {
        foreach ($proj in $projectsToReference) {
            $relativePath = $proj.FullName.Substring($TargetSolutionPath.Length + 1)
            $result = dotnet add "src\CodeGeneratorDev\CodeGeneratorDev.csproj" reference $relativePath 2>&1
            
            if ($LASTEXITCODE -eq 0 -or $result -match "already has a reference") {
                Write-Host "  ✓ Referenced $($proj.Directory.Name)" -ForegroundColor Green
            }
            else {
                Write-Host "  ⚠ Failed to reference $($proj.Directory.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    Pop-Location
    
    Write-Host ""
    Write-Host "Step 4: Updating namespaces..." -ForegroundColor White

    $generatorFiles = Get-ChildItem -Path $targetCodeGenPath -Filter "*.cs" -Recurse
    $updated = 0

    foreach ($file in $generatorFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $modified = $false
    
        # Replace namespace declarations
        if ($content -match 'namespace CodeGeneratorDev') {
            $content = $content -replace 'namespace CodeGeneratorDev', "namespace $projectName.CodeGeneratorDev"
            $modified = $true
        }
    
        # Replace using statements
        if ($content -match 'using CodeGeneratorDev\.') {
            $content = $content -replace 'using CodeGeneratorDev\.', "using $projectName.CodeGeneratorDev."
            $modified = $true
        }
    
        if ($modified) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            $updated++
        }
    }

    Write-Host "  ✓ Updated $updated file(s)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Step 4.5: Adapting for Central Package Management..." -ForegroundColor White

    $csprojPath = Join-Path $targetCodeGenPath "CodeGeneratorDev.csproj"
    $directoryPackagesPath = Join-Path $TargetSolutionPath "Directory.Packages.props"

    if (Test-Path $directoryPackagesPath) {
        Write-Host "  ✓ CPM detected" -ForegroundColor Gray
    
        # Step A: Get packages from CodeGeneratorDev.csproj
        [xml]$csproj = Get-Content $csprojPath
        $requiredPackages = @()
    
        foreach ($itemGroup in $csproj.Project.ItemGroup) {
            if ($itemGroup.PackageReference) {
                foreach ($packageRef in $itemGroup.PackageReference) {
                    $packageName = $packageRef.GetAttribute("Include")
                    $packageVersion = $packageRef.GetAttribute("Version")
                
                    if ($packageName -and $packageVersion) {
                        $requiredPackages += @{
                            Name    = $packageName
                            Version = $packageVersion
                        }
                    
                        # Remove version from .csproj
                        $packageRef.RemoveAttribute("Version")
                    }
                }
            }
        }
    
        $csproj.Save($csprojPath)
        Write-Host "    Stripped versions from $($requiredPackages.Count) packages" -ForegroundColor DarkGray
    
        # Step B: Check Directory.Packages.props for existing packages
        [xml]$dirPackages = Get-Content $directoryPackagesPath
        $existingPackages = @{}
    
        foreach ($itemGroup in $dirPackages.Project.ItemGroup) {
            if ($itemGroup.PackageVersion) {
                foreach ($pkgVer in $itemGroup.PackageVersion) {
                    $name = $pkgVer.GetAttribute("Include")
                    $version = $pkgVer.GetAttribute("Version")
                    $existingPackages[$name] = $version
                }
            }
        }
    
        # Step C: Add only truly missing packages (not already defined)
        $packagesToAdd = @()
    
        foreach ($pkg in $requiredPackages) {
            if (-not $existingPackages.ContainsKey($pkg.Name)) {
                $packagesToAdd += $pkg
            }
            else {
                Write-Host "    ℹ $($pkg.Name) already defined (v$($existingPackages[$pkg.Name]))" -ForegroundColor DarkGray
            }
        }
    
        if ($packagesToAdd.Count -gt 0) {
            Write-Host "    Adding $($packagesToAdd.Count) missing package(s)..." -ForegroundColor Yellow
        
            # Find the first ItemGroup to add packages to
            $itemGroup = $dirPackages.Project.ItemGroup | Select-Object -First 1
        
            foreach ($pkg in $packagesToAdd) {
                Write-Host "      + $($pkg.Name) v$($pkg.Version)" -ForegroundColor DarkGray
            
                $newElement = $dirPackages.CreateElement("PackageVersion")
                $newElement.SetAttribute("Include", $pkg.Name)
                $newElement.SetAttribute("Version", $pkg.Version)
                $itemGroup.AppendChild($newElement) | Out-Null
            }
        
            $dirPackages.Save($directoryPackagesPath)
            Write-Host "    ✓ Updated Directory.Packages.props" -ForegroundColor Green
        }
        else {
            Write-Host "    ✓ All required packages already defined in CPM" -ForegroundColor Green
        }
    
    }
    else {
        Write-Host "  ℹ No CPM detected - keeping package versions" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Step 4.6: Setting nullable to annotations for generated code compatibility..." -ForegroundColor White

    $csprojPath = Join-Path $targetCodeGenPath "CodeGeneratorDev.csproj"
    [xml]$csproj = Get-Content $csprojPath

    # Find or update the Nullable property
    $propertyGroup = $csproj.Project.PropertyGroup | Select-Object -First 1
    $nullableNode = $propertyGroup.SelectSingleNode("Nullable")

    if ($nullableNode) {
        $nullableNode.InnerText = "annotations"
        Write-Host "  ✓ Changed <Nullable> to 'annotations'" -ForegroundColor Green
    }
    else {
        $newElement = $csproj.CreateElement("Nullable")
        $newElement.InnerText = "annotations"
        $propertyGroup.AppendChild($newElement) | Out-Null
        Write-Host "  ✓ Added <Nullable>annotations</Nullable>" -ForegroundColor Green
    }

    $csproj.Save($csprojPath)

    Write-Host ""
    Write-Host "Step 4.7: Setting nullable to annotations in solution-wide settings..." -ForegroundColor White

    $directoryBuildPropsPath = Join-Path $TargetSolutionPath "Directory.Build.props"

    if (Test-Path $directoryBuildPropsPath) {
        $content = Get-Content $directoryBuildPropsPath -Raw
    
        if ($content -match '<Nullable>enable</Nullable>') {
            $content = $content -replace '<Nullable>enable</Nullable>', '<Nullable>annotations</Nullable>'
            Set-Content $directoryBuildPropsPath $content -NoNewline
            Write-Host "  ✓ Changed <Nullable> from 'enable' to 'annotations' in Directory.Build.props" -ForegroundColor Green
        }
        elseif ($content -match '<Nullable>disable</Nullable>') {
            $content = $content -replace '<Nullable>disable</Nullable>', '<Nullable>annotations</Nullable>'
            Set-Content $directoryBuildPropsPath $content -NoNewline
            Write-Host "  ✓ Changed <Nullable> from 'disable' to 'annotations' in Directory.Build.props" -ForegroundColor Green
        }
        else {
            Write-Host "  ℹ Nullable already set to annotations or not found" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  ℹ No Directory.Build.props found" -ForegroundColor Gray
    }


    Write-Host ""
    Write-Host "Step 5: Verifying build..." -ForegroundColor White
    
    Push-Location $TargetSolutionPath
    $buildResult = dotnet build "src\CodeGeneratorDev\CodeGeneratorDev.csproj" --verbosity quiet 2>&1
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Build successful" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Build issues detected - open in VS2022 to review" -ForegroundColor Yellow
    }
    
    # Step 6: Create launchSettings.json for VS2022 debugging
    Write-Host ""
    Write-Host "Step 6: Creating launchSettings.json..." -ForegroundColor White

    $launchSettingsDir = Join-Path $targetCodeGenPath "Properties"
    if (-not (Test-Path $launchSettingsDir)) {
        New-Item -ItemType Directory -Path $launchSettingsDir -Force | Out-Null
    }

    $launchSettingsFile = Join-Path $launchSettingsDir "launchSettings.json"

    # Create JSON with relative paths from solution root
    $launchSettings = @{
        profiles = @{
            "DryRun (Safe)"                  = @{
                commandName      = "Project"
                workingDirectory = "`$(SolutionDir)"
                commandLineArgs  = "artifacts/bin/Domain/debug/$projectName.Domain.dll . $projectName --dry-run"
            }
            "Production (Writes to Project)" = @{
                commandName      = "Project"
                workingDirectory = "`$(SolutionDir)"
                commandLineArgs  = "artifacts/bin/Domain/release/$projectName.Domain.dll . $projectName"
            }
        }
    }

    $launchSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $launchSettingsFile -Encoding UTF8
    Write-Host "  ✓ Created launchSettings.json with relative paths" -ForegroundColor Green


    Write-Host ""
    Write-Host "=== COPY COMPLETE ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Original CodeGeneratorDev remains at: $CodeGenSourcePath" -ForegroundColor Gray
    Write-Host "Copy integrated into: $projectName" -ForegroundColor White
    Write-Host ""
    Write-Host "Next: Open $projectName.sln in Visual Studio" -ForegroundColor White
    Write-Host ""
    
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}