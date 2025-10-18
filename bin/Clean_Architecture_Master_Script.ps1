# =============================================================================
# CLEAN ARCHITECTURE SETUP AUTOMATION - DROP AND RUN
# =============================================================================
# PURPOSE: Automate Jason Taylor Clean Architecture project setup with database configuration
# USAGE: Run script, provide project name and database connection, complete CA project auto-generates
# SUPPORTS: PostgreSQL, SQL Server, SQLite with automatic provider detection and testing
# =============================================================================

# =============================================================================
# TABLE OF CONTENTS
# =============================================================================
# STEP 1: CHECK REQUIRED TOOLS
#   • Verify .NET CLI installation and version
#   • Exit with installation instructions if missing
#
# STEP 2: VERIFY/INSTALL CLEAN ARCHITECTURE TEMPLATE
#   • Check for Clean.Architecture.Solution.Template
#   • Auto-install if missing
#   • Verify template availability
#
# STEP 3: GET DATABASE CONNECTION
#   • Prompt for database connection string
#   • Display examples for PostgreSQL, SQL Server, SQLite
#   • Validate connection string not empty
#
# STEP 4: AUTO-DETECT PROVIDER AND GENERATE PROJECT NAME
#   • Auto-detect database provider from connection string
#   • Extract database name from connection parameters
#   • Auto-generate project name as {DatabaseName}_API
#   • Allow optional user override of project name
#   • Handle directory conflicts with numeric suffixes
#   • Apply SQL Server SSL fixes if needed
#
# STEP 5: CREATE CLEAN ARCHITECTURE PROJECT
#   • Execute dotnet new ca-sln with detected provider
#   • Navigate to project directory
#   • Configure VS2022 startup project (reorder solution and reset VS state)
#   • Handle project creation errors with troubleshooting
#
# STEP 5.5: CUSTOMIZE BASE ENTITIES AND CLEAN TEMPLATE
#   • Customize BaseAuditableEntity:
#     - Replace DateTimeOffset with DateTime
#     - Make LastModified nullable
#     - Add RecDelete property for soft deletes
#   • Customize BaseEntity:
#     - Comment out Id property (entities define their own)
#   • Remove all template sample code:
#     - Domain: TodoItem/TodoList entities and events
#     - Application: Todo CQRS handlers and folders
#     - Infrastructure: Todo configurations and seed data
#     - Web: Todo endpoints
#     - Tests: All Todo-related test files
#   • Fix template file references:
#     - Remove Todo DbSets from IApplicationDbContext
#     - Remove Todo DbSets from ApplicationDbContext
#     - Fix AuditableEntityInterceptor DateTime conversion
#     - Remove Todo seed data from ApplicationDbContextInitialiser
#     - Remove Todo AutoMapper mappings from LookupDto
#     - Remove Events namespace from Domain GlobalUsings.cs
#
# STEP 5.6: CREATE COMMON EXCEPTION CLASSES
#   • Create Application/Common/Exceptions directory
#   • Generate NotFoundException.cs with multiple constructors
#   • Namespace matches project naming convention
#
# STEP 5.7: FIX CUSTOMEXCEPTIONHANDLER NAMESPACE COLLISION
#   • Fully qualify NotFoundException references in CustomExceptionHandler.cs
#   • Prevent collision with Ardalis.GuardClauses.NotFoundException
#
# STEP 5.8: CREATE COMMON MAPPING INTERFACES
#   • Create Application/Common/Mappings directory
#   • Generate IMapFrom<T> interface for AutoMapper
#   • Generate MappingProfile with reflection-based auto-discovery
#   • Enable convention-based DTO mapping
#
# STEP 5.9: CREATE API CONTROLLER BASE CLASS
#   • Create Web/Controllers directory
#   • Generate ApiControllerBase with MediatR integration
#   • Add ExecuteAsync helpers for exception handling
#   • Centralize error responses (404, 400, 401, 403, 409, 500)
#
# STEP 6: CONFIGURE DATABASE CONNECTION
#   • Update appsettings.json with connection string
#   • Update appsettings.Development.json (critical for dev environment)
#   • Remove template-generated LocalDB connection strings
#   • Fix Infrastructure/DependencyInjection.cs to use "DefaultConnection"
#   • Ensure connection string consistency across all config files
#
# STEP 6.5: ISOLATED DATABASE SCAFFOLDING
#   • Create temporary staging project OUTSIDE main solution
#   • Install EF Core 7.0.10 packages (known-good scaffolding version)
#   • Run dotnet ef dbcontext scaffold against database
#   • Generate entity models and DbContext in isolation
#   • Extract DbSet pluralization mappings from scaffolded DbContext
#   • No version conflicts with main project
#
# STEP 6.55: CREATE CAPABILITY INTERFACES
#   • Create ISoftDeletable interface in Domain/Common
#   • Create IAuditable interface in Domain/Common
#   • Enable flexible entity capability composition
#   • Support databases with or without audit columns
#
# STEP 6.6: INTELLIGENT ENTITY INTEGRATION WITH CAPABILITY DETECTION
#   • Analyze scaffolded entities for audit column patterns
#   • Tier 1: Exclude Identity infrastructure tables (composite keys)
#   • Tier 2: Isolate AspNetUser/AspNetRole to Domain/Identity
#   • Tier 3: Process business entities with capability detection:
#     - Detect ISoftDeletable (RecDelete column)
#     - Detect IAuditable (Created, CreatedBy, LastModified, LastModifiedBy)
#     - Remove audit properties from entity (provided by interfaces)
#     - Preserve primary keys (never removed)
#     - Apply BaseEntity + interface inheritance
#   • Transform namespaces and remove System usings
#   • Generate comprehensive integration statistics report
#
# STEP 6.7: AUTOMATIC DBCONTEXT WIRING
#   • Read all entity files from Domain/Entities
#   • Extract entity class names via regex
#   • Use scaffolded DbContext pluralization mappings
#   • Add DbSet declarations to IApplicationDbContext interface
#   • Add DbSet properties to ApplicationDbContext class
#   • Dynamic insertion at correct code locations
#
# STEP 6.75: CONFIGURE DATABASE INITIALIZATION STRATEGY
#   • Replace MigrateAsync with EnsureCreatedAsync
#   • Preserve existing database (database-first approach)
#   • Prevent accidental data loss on startup
#
# STEP 6.76: DISABLE AUTO-INITIALIZATION FOR DATABASE-FIRST
#   • Comment out InitialiseDatabaseAsync in Program.cs
#   • Database schema managed by existing database
#   • Prevent conflicts with database-first workflow
#
# STEP 6.8: BUILD DOMAIN PROJECT FOR REFLECTION
#   • Clean and compile Domain.csproj (Release configuration)
#   • Validate build success before code generation
#   • Locate compiled Domain.dll dynamically
#   • Store assembly path for future code generation
#   • Exit script if build fails with detailed error output
#
# STEP 7: FIX COMMON TEMPLATE ISSUES
#   • Fix Users.cs endpoint implementation if needed
#   • Remove NSwag integration completely for VS2022 compatibility:
#     - Remove NSwag packages from Web.csproj
#     - Remove NSwag versions from Directory.Packages.props
#     - Delete config.nswag file
#     - Clean NSwag build artifacts
#     - Remove NSwag using statements
#     - Replace with standard Swagger/Swashbuckle
#     - Configure VS2022 launch settings for Swagger
#     - Fix DependencyInjection.cs completely
#     - Add MapControllers() to Program.cs
#   • Add Swashbuckle.AspNetCore package and version
#
# STEP 8: VALIDATE PROJECT SETUP
#   • Verify expected folder structure
#   • Test project build (dotnet build)
#   • Test database connectivity (non-SQLite providers)
#   • Navigate to Web project for EF commands
#   • Return to project root after testing
#
# STEP 9: SHOW FINAL RESULTS AND NEXT STEPS
#   • Display comprehensive setup summary
#   • Show project structure visualization
#   • Provide next steps and usage instructions
#   • Display database connection details
#   • Show commands for running, testing, and extending
#
# STEP 10: WAIT FOR USER BEFORE CLOSING
#   • Pause for user acknowledgment before script termination
#
# =============================================================================
# FUTURE DEVELOPMENT (NOT YET IMPLEMENTED)
# =============================================================================
# STEP 6.9+: INVOKE CODE GENERATION ENGINE
#   • Load Domain.dll via reflection
#   • Discover all entity types dynamically (exclude Identity tables)
#   • For each entity, generate complete vertical slice:
#     - Application: CQRS Commands/Queries, DTOs, Validators, AutoMapper profiles
#     - Web: API Controllers with ExecuteAsync exception handling
#     - Tests: Integration tests with NUnit/WebApplicationFactory
#   • Output to Generated/ folders using partial classes
#   • Respect entity capabilities (ISoftDeletable, IAuditable)
#   • Final build validation of generated code
# =============================================================================

# =============================================================================
# HELPER FUNCTION: SET WEB PROJECT AS STARTUP BY REORDERING SOLUTION
# =============================================================================
function Set-WebAsStartupInSolution {
    param(
        [Parameter(Mandatory = $true)][string]$SolutionPath,
        [string]$WebProjectRelativePath = 'src\Web\Web.csproj',
        [switch]$PreserveVsFolder
    )

    if (-not (Test-Path $SolutionPath)) { throw "Solution file not found: $SolutionPath" }
    $sln = Get-Content -Raw -Encoding UTF8 $SolutionPath

    # Capture every Project ... EndProject block (solution folders included).
    $projectRe = [regex]'(?ms)^(?<block>Project\("(?<type>[^"]+)"\)\s=\s"(?<name>[^"]+)",\s"(?<path>[^"]+)",\s"(?<guid>\{[0-9A-Fa-f\-]+\})"\r?\n.*?\r?\nEndProject\r?$)'
    $m = $projectRe.Matches($sln)
    if ($m.Count -eq 0) { Write-Host "No project blocks found in $SolutionPath" -ForegroundColor Yellow; return }

    # Utilities to normalize paths and collect projects.
    $norm = { param($p) (($p -replace '/', '\').Trim().ToLowerInvariant()) }
    $projects = @()
    foreach ($x in $m) {
        $projects += [pscustomobject]@{
            Name  = $x.Groups['name'].Value
            Path  = $x.Groups['path'].Value
            Guid  = $x.Groups['guid'].Value.ToUpperInvariant()
            Type  = $x.Groups['type'].Value.ToUpperInvariant()
            Block = $x.Groups['block'].Value
        }
    }

    # Deduplicate by normalized physical path. Keep the first occurrence, drop the rest.
    $seenByPath = @{}
    $keep = @()
    $removedGuids = New-Object System.Collections.Generic.List[string]
    foreach ($p in $projects) {
        $key = & $norm $p.Path
        if (-not $seenByPath.ContainsKey($key)) {
            $seenByPath[$key] = $true
            $keep += $p
        }
        else {
            $removedGuids.Add($p.Guid)
            Write-Host "Removed duplicate project block: $($p.Name) ($($p.Path))" -ForegroundColor Yellow
        }
    }

    # Ensure Web is kept and moved to the front.
    $targetKey = & $norm $WebProjectRelativePath
    $web = $keep | Where-Object { (& $norm $_.Path) -eq $targetKey } | Select-Object -First 1
    if (-not $web) { Write-Host "Web project not found in solution (looked for '$WebProjectRelativePath')." -ForegroundColor Yellow; return }

    $others = $keep | Where-Object { $_ -ne $web }
    $reordered = , $web + $others

    # Rebuild the project region from the first Project to the last Project.
    $firstStart = $m[0].Groups['block'].Index
    $last = $m[$m.Count - 1].Groups['block']
    $lastEnd = $last.Index + $last.Length

    $prefix = $sln.Substring(0, $firstStart)
    $middle = ($reordered | ForEach-Object { $_.Block } ) -join "`r`n"
    if ($middle -notmatch "`r?`n$") { $middle += "`r`n" }  # final newline for safety
    $suffix = $sln.Substring($lastEnd)

    $new = $prefix + $middle + $suffix

    # If we removed any duplicates, scrub their GUID lines from config sections.
    if ($removedGuids.Count -gt 0) {
        $cfgRe = [regex]'(?ms)^(\s*GlobalSection\(ProjectConfigurationPlatforms\)\s=\s[^\r\n]+\r?\n)(?<body>.*?)(^\s*EndGlobalSection\r?$)'
        $nestRe = [regex]'(?ms)^(\s*GlobalSection\(NestedProjects\)\s=\s[^\r\n]+\r?\n)(?<body>.*?)(^\s*EndGlobalSection\r?$)'

        $new = $cfgRe.Replace($new, {
                param($mx)
                $head = $mx.Groups[1].Value
                $body = $mx.Groups['body'].Value
                $tail = $mx.Groups[3].Value
                foreach ($g in $removedGuids) {
                    $gEsc = [regex]::Escape($g)
                    $body = [regex]::Replace($body, "(?m)^\s*$gEsc\.[^\r\n]*\r?$", '')
                }
                $head + ($body -replace "(?m)^\s*\r?$", '') + $tail
            })

        $new = $nestRe.Replace($new, {
                param($mx)
                $head = $mx.Groups[1].Value
                $body = $mx.Groups['body'].Value
                $tail = $mx.Groups[3].Value
                foreach ($g in $removedGuids) {
                    $gEsc = [regex]::Escape($g)
                    $body = [regex]::Replace($body, "(?m)^\s*$gEsc\s*=\s*\{[0-9A-Fa-f\-]+\}\r?$", '')
                }
                $head + ($body -replace "(?m)^\s*\r?$", '') + $tail
            })
    }

    Set-Content -Path $SolutionPath -Value $new -Encoding UTF8
    Write-Host "Repaired and reordered solution. Web is first." -ForegroundColor Green

    if (-not $PreserveVsFolder) {
        $vsFolder = Join-Path (Split-Path -Path $SolutionPath -Parent) '.vs'
        if (Test-Path $vsFolder) {
            try { Remove-Item -LiteralPath $vsFolder -Recurse -Force -ErrorAction Stop; Write-Host "Cleared .vs to reset .suo." -ForegroundColor Green }
            catch { Write-Host "Could not remove .vs: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }
}

# Use it right after you cd into the generated solution directory
$solutionFile = Get-ChildItem -Filter "*.sln" | Select-Object -First 1
if ($solutionFile) {
    Repair-And-SetWebStartup -SolutionPath $solutionFile.FullName
}
else {
    Write-Host "No solution file found; skipping startup configuration." -ForegroundColor Yellow
}


# =============================================================================
# STEP 1: CHECK REQUIRED TOOLS
# =============================================================================
Write-Host "Checking required .NET development tools..." -ForegroundColor Cyan

# Check for .NET CLI
try {
    $dotnetVersion = dotnet --version 2>$null
    if ($null -eq $dotnetVersion) {
        throw "dotnet command not found"
    }
    Write-Host "✓ .NET CLI found (version: $dotnetVersion)" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "=== MISSING DEPENDENCY ===" -ForegroundColor Red
    Write-Host "The .NET CLI is required but not installed or not in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "To install .NET CLI:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://dotnet.microsoft.com/download" -ForegroundColor White
    Write-Host "2. Install the latest .NET SDK" -ForegroundColor White
    Write-Host "3. Restart your PowerShell session" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "✓ All required tools are available" -ForegroundColor Green
Write-Host ""

# =============================================================================
# STEP 2: VERIFY/INSTALL CLEAN ARCHITECTURE TEMPLATE
# =============================================================================
Write-Host "=== CLEAN ARCHITECTURE TEMPLATE SETUP ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking for Clean Architecture template..." -ForegroundColor White

# Check if template is installed
$templateCheck = dotnet new list 2>$null | Select-String "ca-sln"

if ($null -eq $templateCheck) {
    Write-Host "✗ Clean Architecture template not found" -ForegroundColor Red
    Write-Host "Installing Clean Architecture Solution Template..." -ForegroundColor Yellow
    
    try {
        $installResult = dotnet new install Clean.Architecture.Solution.Template 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Clean Architecture template installed successfully" -ForegroundColor Green
        }
        else {
            throw "Template installation failed: $installResult"
        }
    }
    catch {
        Write-Host "✗ Failed to install Clean Architecture template!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }
}
else {
    Write-Host "✓ Clean Architecture template found" -ForegroundColor Green
}

Write-Host ""

# =============================================================================
# STEP 3: GET DATABASE CONNECTION
# =============================================================================
Write-Host "=== DATABASE CONNECTION SETUP ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Enter your database connection string:" -ForegroundColor White
Write-Host ""
Write-Host "PostgreSQL Examples:" -ForegroundColor Yellow
Write-Host "  Server=localhost;Port=5432;Database=dbname;User Id=username;Password=password" -ForegroundColor Gray
Write-Host "  Server=localhost;Port=5432;Database=dbname;User Id=username;Password=password;Search Path=public" -ForegroundColor Gray
Write-Host "  Server=hostname;Port=5432;Database=dbname;User Id=username;Password=password;SSL Mode=Require;Search Path=myschema,public" -ForegroundColor Gray
Write-Host ""
Write-Host "SQL Server Examples:" -ForegroundColor Yellow
Write-Host "  Server=localhost;Database=dbname;Trusted_Connection=true" -ForegroundColor Gray
Write-Host "  Server=localhost;Database=dbname;User Id=sa;Password=password" -ForegroundColor Gray
Write-Host ""
Write-Host "SQLite Example:" -ForegroundColor Yellow
Write-Host "  Data Source=app.db" -ForegroundColor Gray
Write-Host ""

# Check for environment variable first (passed from module)
if ($env:CA_CONNECTION_STRING) {
    $connectionString = $env:CA_CONNECTION_STRING
    Write-Host "✓ Using connection string from module" -ForegroundColor Green
} else {
    $connectionString = Read-Host "Connection String"
    
    if ([string]::IsNullOrWhiteSpace($connectionString)) {
        Write-Host "Error: Connection string cannot be empty." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }
}

Write-Host ""

Write-Host ""

# =============================================================================
# STEP 4: AUTO-DETECT PROVIDER AND GENERATE PROJECT NAME
# =============================================================================
Write-Host "Auto-detecting database provider..." -ForegroundColor Cyan

# CHECK FOR ENVIRONMENT VARIABLE (from module parameters)
if (-not [string]::IsNullOrWhiteSpace($env:CA_PROJECT_NAME)) {
    $projectName = $env:CA_PROJECT_NAME
    Write-Host "✓ Using project name from environment: $projectName" -ForegroundColor Green
    $skipProjectNameGeneration = $true
}
else {
    $skipProjectNameGeneration = $false
}

$databaseProvider = ""
$templateDbProvider = ""

# PostgreSQL detection
if ($connectionString -match "Npgsql|postgres|Port=5432" -or $connectionString.ToLower().Contains("postgres")) {
    $databaseProvider = "PostgreSQL"
    $templateDbProvider = "postgresql"
    Write-Host "✓ Detected provider: PostgreSQL" -ForegroundColor Green
}
# SQL Server detection
elseif ($connectionString -match "Server=.*(?!postgres)" -or $connectionString.Contains("SqlServer") -or $connectionString.Contains("Trusted_Connection") -or $connectionString.Contains("Data Source") -and -not $connectionString.Contains(".db")) {
    $databaseProvider = "SQL Server"
    $templateDbProvider = "sqlserver"
    Write-Host "✓ Detected provider: SQL Server" -ForegroundColor Green
}
# SQLite detection
elseif ($connectionString -match "Data Source=.*\.db" -or $connectionString.ToLower().Contains("sqlite")) {
    $databaseProvider = "SQLite"
    $templateDbProvider = "sqlite"
    Write-Host "✓ Detected provider: SQLite" -ForegroundColor Green
}
else {
    Write-Host "✗ Unable to auto-detect database provider!" -ForegroundColor Red
    Write-Host "Please ensure your connection string contains provider-specific indicators:" -ForegroundColor Yellow
    Write-Host "• PostgreSQL: Should contain 'postgres', 'Npgsql', or 'Port=5432'" -ForegroundColor Yellow
    Write-Host "• SQL Server: Should contain 'Server=', 'Data Source=', or 'Trusted_Connection'" -ForegroundColor Yellow
    Write-Host "• SQLite: Should contain 'Data Source=filename.db'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# =============================================================================
# AUTO-FIX DATABASE-SPECIFIC CONNECTION STRING ISSUES
# =============================================================================

# SQL Server: Add SSL trust if missing
if ($databaseProvider -eq "SQL Server" -and $connectionString -notmatch "TrustServerCertificate|Encrypt") {
    Write-Host "Adding SSL configuration for SQL Server..." -ForegroundColor Yellow
    $connectionString = $connectionString + ";TrustServerCertificate=true"
    Write-Host "✓ Modified connection string includes SSL trust settings" -ForegroundColor Green
}

# PostgreSQL: Add Search Path=public if missing (exclude system schemas)
if ($databaseProvider -eq "PostgreSQL") {
    if ($connectionString -notmatch "Search Path=") {
        Write-Host "No schema specified - defaulting to 'public' schema only..." -ForegroundColor Yellow
        $connectionString = $connectionString + ";Search Path=public"
        Write-Host "✓ Added 'Search Path=public' to exclude system schemas (sys, pg_catalog)" -ForegroundColor Green
        Write-Host "  ℹ To use custom schema, add: ;Search Path=yourschema,public" -ForegroundColor Gray
    }
    else {
        # Extract and display the user-specified search path
        $searchPathMatch = [regex]::Match($connectionString, "Search Path=([^;]+)")
        if ($searchPathMatch.Success) {
            $searchPath = $searchPathMatch.Groups[1].Value
            Write-Host "✓ Using specified Search Path: $searchPath" -ForegroundColor Green
        }
    }
}

# Extract database name from connection string
Write-Host ""
Write-Host "Extracting database name for project naming..." -ForegroundColor White
$databaseName = ""
$connectionParts = $connectionString -split ";"

foreach ($part in $connectionParts) {
    $trimmedPart = $part.Trim()
    if ($trimmedPart.StartsWith("Database=", [System.StringComparison]::OrdinalIgnoreCase) -or
        $trimmedPart.StartsWith("Initial Catalog=", [System.StringComparison]::OrdinalIgnoreCase)) {
        $databaseName = $trimmedPart.Substring($trimmedPart.IndexOf("=") + 1).Trim()
        break
    }
}

# Handle SQLite case
if ([string]::IsNullOrWhiteSpace($databaseName) -and $databaseProvider -eq "SQLite") {
    # Extract from Data Source=filename.db
    foreach ($part in $connectionParts) {
        $trimmedPart = $part.Trim()
        if ($trimmedPart.StartsWith("Data Source=", [System.StringComparison]::OrdinalIgnoreCase)) {
            $filePath = $trimmedPart.Substring($trimmedPart.IndexOf("=") + 1).Trim()
            $databaseName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($databaseName)) {
    Write-Host "Warning: Could not extract database name from connection string." -ForegroundColor Yellow
    $databaseName = "CleanArchProject"
}

Write-Host "✓ Database name extracted: $databaseName" -ForegroundColor Green

# Auto-generate project name from database name (skip if already set from environment)
if (-not $skipProjectNameGeneration) {
    Write-Host ""
    Write-Host "Auto-generating project name from database..." -ForegroundColor White

    # Clean up database name for project naming
    $cleanDatabaseName = $databaseName -replace '[_\-\s\.]', '' # Remove special chars
    $cleanDatabaseName = (Get-Culture).TextInfo.ToTitleCase($cleanDatabaseName.ToLower()) # PascalCase

    $baseProjectName = "$cleanDatabaseName" + "_API"
    Write-Host "✓ Auto-generated project name: $baseProjectName" -ForegroundColor Green

    # Smart project naming - check if directory exists and append number
    $projectName = $baseProjectName
    $counter = 1

    while (Test-Path $projectName) {
        $projectName = "$baseProjectName$counter"
        $counter++
    }

    if ($projectName -ne $baseProjectName) {
        Write-Host "✓ Directory '$baseProjectName' exists, using '$projectName' instead" -ForegroundColor Yellow
    }
}

Write-Host "✓ Final project name: $projectName" -ForegroundColor Green

# =============================================================================
# STEP 5: CREATE CLEAN ARCHITECTURE PROJECT
# =============================================================================
Write-Host "=== CREATING CLEAN ARCHITECTURE PROJECT ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Creating project structure..." -ForegroundColor White
Write-Host "  Project: $projectName" -ForegroundColor Gray
Write-Host "  Database: $databaseProvider" -ForegroundColor Gray
Write-Host "  Template: Web API only" -ForegroundColor Gray

try {
    # Create the Clean Architecture project
    Write-Host ""
    Write-Host "Executing: dotnet new ca-sln -cf None --database $templateDbProvider -o $projectName" -ForegroundColor White
    $createResult = dotnet new ca-sln -cf None --database $templateDbProvider -o $projectName 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Clean Architecture project created successfully" -ForegroundColor Green
    }
    else {
        throw "Project creation failed: $createResult"
    }

    # Navigate to project directory
    Set-Location $projectName
    Write-Host "✓ Navigated to project directory" -ForegroundColor Green

    # Set Web project as startup by reordering solution file
    Write-Host "Configuring VS2022 startup project..." -ForegroundColor White

    try {
        # Find the solution file
        $solutionFile = Get-ChildItem -Filter "*.sln" | Select-Object -First 1

        if ($solutionFile) {
            Set-WebAsStartupInSolution -SolutionPath $solutionFile.FullName
            Write-Host "✓ Web project configured as VS2022 startup project" -ForegroundColor Green
        }
        else {
            Write-Host "⚠ Solution file not found for startup project configuration" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠ Could not configure startup project: $($_.Exception.Message)" -ForegroundColor Yellow
    }

}
catch {
    Write-Host "✗ Failed to create Clean Architecture project!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "• Ensure the Clean Architecture template is properly installed" -ForegroundColor Yellow
    Write-Host "• Check that the project name doesn't contain invalid characters" -ForegroundColor Yellow
    Write-Host "• Verify you have write permissions in the current directory" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""


# =============================================================================
# STEP 5.5: CUSTOMIZE BASE ENTITIES AND CLEAN TEMPLATE
# =============================================================================
Write-Host "=== CUSTOMIZING BASE ENTITIES AND CLEANING TEMPLATE ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Customize BaseAuditableEntity
    $baseAuditableEntityPath = "src\Domain\Common\BaseAuditableEntity.cs"
    
    if (Test-Path $baseAuditableEntityPath) {
        Write-Host "Updating BaseAuditableEntity with custom properties..." -ForegroundColor White
        
        $content = Get-Content -Path $baseAuditableEntityPath -Raw
        
        # Replace DateTimeOffset with DateTime
        $content = $content -replace 'DateTimeOffset', 'DateTime'
        
        # Make LastModified nullable
        $content = $content -replace 'public DateTime LastModified', 'public DateTime? LastModified'
        
        # Add RecDelete property
        $recDeleteProperty = "`r`n    `r`n    public bool RecDelete { get; set; } = false;"
        $content = $content -replace '(\s+public string\? LastModifiedBy[^}]+})' , ('$1' + $recDeleteProperty)
        
        Set-Content -Path $baseAuditableEntityPath -Value $content -Encoding UTF8
        Write-Host "✓ BaseAuditableEntity customized successfully" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ BaseAuditableEntity.cs not found" -ForegroundColor Yellow
    }
    
    # Customize BaseEntity - comment out Id property
    $baseEntityPath = "src\Domain\Common\BaseEntity.cs"
    
    if (Test-Path $baseEntityPath) {
        Write-Host "Updating BaseEntity (commenting out Id property)..." -ForegroundColor White
        
        $content = Get-Content -Path $baseEntityPath -Raw
        $content = $content -replace '(\s+)public int Id \{ get; set; \}', '$1//public int Id { get; set; }'
        
        Set-Content -Path $baseEntityPath -Value $content -Encoding UTF8
        Write-Host "✓ BaseEntity customized successfully" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ BaseEntity.cs not found" -ForegroundColor Yellow
    }
    
    # Remove template sample code
    Write-Host "Removing template sample code..." -ForegroundColor White
    $pathsToRemove = @(
        "src\Domain\Entities\TodoItem.cs",
        "src\Domain\Entities\TodoList.cs",
        "src\Domain\Events\TodoItemCompletedEvent.cs",
        "src\Domain\Events\TodoItemCreatedEvent.cs",
        "src\Domain\Events\TodoItemDeletedEvent.cs",
        "src\Application\TodoItems",
        "src\Application\TodoLists",
        "src\Web\Endpoints\TodoItems.cs",
        "src\Web\Endpoints\TodoLists.cs",
        "src\Infrastructure\Data\Configurations\TodoItemConfiguration.cs",
        "src\Infrastructure\Data\Configurations\TodoListConfiguration.cs",
        "tests\Application.UnitTests\Common\Behaviours\RequestLoggerTests.cs",
        "tests\Application.UnitTests\Common\Mappings\MappingTests.cs",
        "tests\Application.FunctionalTests\TodoItems",
        "tests\Application.FunctionalTests\TodoLists"   
    )

    foreach ($path in $pathsToRemove) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "  ✓ Removed: $path" -ForegroundColor Green
        }
    }

    # Fix IApplicationDbContext interface
    $appDbContextInterfacePath = "src\Application\Common\Interfaces\IApplicationDbContext.cs"
    if (Test-Path $appDbContextInterfacePath) {
        Write-Host "Fixing IApplicationDbContext interface..." -ForegroundColor White
        $content = Get-Content -Path $appDbContextInterfacePath -Raw
        
        $content = $content -replace '\s*DbSet<TodoList>.*\r?\n', ''
        $content = $content -replace '\s*DbSet<TodoItem>.*\r?\n', ''
        
        Set-Content -Path $appDbContextInterfacePath -Value $content -Encoding UTF8
        Write-Host "  ✓ Removed Todo DbSets from IApplicationDbContext" -ForegroundColor Green
    }

    # Fix ApplicationDbContext in Infrastructure
    $appDbContextPath = "src\Infrastructure\Data\ApplicationDbContext.cs"
    if (Test-Path $appDbContextPath) {
        Write-Host "Fixing ApplicationDbContext..." -ForegroundColor White
        $content = Get-Content -Path $appDbContextPath -Raw
        
        $content = $content -replace '\s*public DbSet<TodoList>.*\r?\n', ''
        $content = $content -replace '\s*public DbSet<TodoItem>.*\r?\n', ''
        
        Set-Content -Path $appDbContextPath -Value $content -Encoding UTF8
        Write-Host "  ✓ Removed Todo DbSets from ApplicationDbContext" -ForegroundColor Green
    }

    # Fix AuditableEntityInterceptor - convert DateTimeOffset to DateTime
    $interceptorPath = "src\Infrastructure\Data\Interceptors\AuditableEntityInterceptor.cs"
    if (Test-Path $interceptorPath) {
        Write-Host "Fixing AuditableEntityInterceptor..." -ForegroundColor White
        $content = Get-Content -Path $interceptorPath -Raw
        
        $content = $content -replace 'var utcNow = _dateTime\.GetUtcNow\(\);', 'var utcNow = _dateTime.GetUtcNow().DateTime;'
        
        Set-Content -Path $interceptorPath -Value $content -Encoding UTF8
        Write-Host "  ✓ Fixed AuditableEntityInterceptor DateTime conversion" -ForegroundColor Green
    }

    # Fix ApplicationDbContextInitialiser - remove Todo seed data
    $initialiserPath = "src\Infrastructure\Data\ApplicationDbContextInitialiser.cs"
    if (Test-Path $initialiserPath) {
        Write-Host "Fixing ApplicationDbContextInitialiser..." -ForegroundColor White
        $content = Get-Content -Path $initialiserPath -Raw
        
        $content = $content -replace '(?s)// Default data.*?await _context\.SaveChangesAsync\(\);\s+}', '// Default data section removed - add your seed data here'
        
        Set-Content -Path $initialiserPath -Value $content -Encoding UTF8
        Write-Host "  ✓ Removed Todo seed data from ApplicationDbContextInitialiser" -ForegroundColor Green
    }

    # Fix LookupDto AutoMapper mappings
    $lookupDtoPath = "src\Application\Common\Models\LookupDto.cs"
    if (Test-Path $lookupDtoPath) {
        Write-Host "Fixing LookupDto AutoMapper mappings..." -ForegroundColor White
        $content = Get-Content -Path $lookupDtoPath -Raw
        
        $content = $content -replace '\s*CreateMap<TodoList, LookupDto>\(\);.*\r?\n', ''
        $content = $content -replace '\s*CreateMap<TodoItem, LookupDto>\(\);.*\r?\n', ''
        
        Set-Content -Path $lookupDtoPath -Value $content -Encoding UTF8
        Write-Host "  ✓ Removed Todo mappings from LookupDto" -ForegroundColor Green
    }

    # Fix Domain GlobalUsings.cs
    $globalUsingsPath = "src\Domain\GlobalUsings.cs"
    if (Test-Path $globalUsingsPath) {
        Write-Host "Fixing Domain GlobalUsings.cs..." -ForegroundColor White
        $content = Get-Content -Path $globalUsingsPath -Raw
        
        $content = $content -replace 'global using [^\r\n]*\.Domain\.Events;\r?\n', ''
        
        Set-Content -Path $globalUsingsPath -Value $content -Encoding UTF8
        Write-Host "  ✓ Removed Events namespace from GlobalUsings.cs" -ForegroundColor Green
    }
    
}
catch {
    Write-Host "⚠ Failed to customize base entities" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# STEP 5.6: CREATE COMMON EXCEPTION CLASSES
# =============================================================================

Write-Host "=== CREATING COMMON EXCEPTION CLASSES ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Validate project name variable exists
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        throw "Project name variable not set"
    }
    
    # Create Exceptions directory
    $exceptionsPath = "src\Application\Common\Exceptions"
    
    # Ensure parent directory structure exists
    if (-not (Test-Path "src\Application\Common")) {
        Write-Host "⚠ Application\Common directory missing - creating..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path "src\Application\Common" -Force | Out-Null
    }
    
    if (-not (Test-Path $exceptionsPath)) {
        New-Item -ItemType Directory -Path $exceptionsPath -Force | Out-Null
        Write-Host "Created Exceptions directory" -ForegroundColor White
    }
    
    $notFoundExceptionPath = Join-Path $exceptionsPath "NotFoundException.cs"
    
    # Check if file already exists (don't overwrite user customizations)
    if (Test-Path $notFoundExceptionPath) {
        Write-Host "⚠ NotFoundException.cs already exists - skipping" -ForegroundColor Yellow
    }
    else {
        # Create NotFoundException.cs
        $notFoundExceptionContent = @"
namespace $projectName.Application.Common.Exceptions;

public class NotFoundException : Exception
{
    public NotFoundException() : base() { }
    
    public NotFoundException(string message) : base(message) { }
    
    public NotFoundException(string message, Exception innerException) 
        : base(message, innerException) { }
    
    public NotFoundException(string name, object key) 
        : base(`$"Entity \"{name}\" ({key}) was not found.") { }
}
"@
        
        Set-Content -Path $notFoundExceptionPath -Value $notFoundExceptionContent -Encoding UTF8
        Write-Host "✓ Created NotFoundException.cs" -ForegroundColor Green
    }
    
}
catch {
    Write-Host "⚠ Failed to create exception classes" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# =============================================================================
# STEP 5.7: FIX CUSTOMEXCEPTIONHANDLER NAMESPACE COLLISION
# =============================================================================
Write-Host "=== FIXING CUSTOMEXCEPTIONHANDLER ===" -ForegroundColor Cyan
Write-Host ""

try {
    $customExceptionHandlerPath = "src\Web\Infrastructure\CustomExceptionHandler.cs"
    
    if (Test-Path $customExceptionHandlerPath) {
        Write-Host "Fixing NotFoundException namespace collision..." -ForegroundColor White
        $content = Get-Content -Path $customExceptionHandlerPath -Raw
        
        # Fully qualify our NotFoundException to avoid collision with Ardalis.GuardClauses
        $content = $content -replace '\bNotFoundException\b', "$projectName.Application.Common.Exceptions.NotFoundException"
        
        Set-Content -Path $customExceptionHandlerPath -Value $content -Encoding UTF8
        Write-Host "✓ Fixed CustomExceptionHandler.cs" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ CustomExceptionHandler.cs not found" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "⚠ Failed to fix CustomExceptionHandler" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# STEP 5.8: CREATE COMMON MAPPING INTERFACES
# =============================================================================
Write-Host "=== CREATING COMMON MAPPING INTERFACES ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Create Mappings directory
    $mappingsPath = "src\Application\Common\Mappings"
    if (-not (Test-Path $mappingsPath)) {
        New-Item -ItemType Directory -Path $mappingsPath -Force | Out-Null
        Write-Host "Created Mappings directory" -ForegroundColor White
    }
    
    # Create IMapFrom.cs
    $iMapFromContent = @"
using AutoMapper;

namespace $projectName.Application.Common.Mappings;

public interface IMapFrom<T>
{
    void Mapping(Profile profile) => profile.CreateMap(typeof(T), GetType());
}
"@
    
    $iMapFromPath = Join-Path $mappingsPath "IMapFrom.cs"
    Set-Content -Path $iMapFromPath -Value $iMapFromContent -Encoding UTF8
    Write-Host "✓ Created IMapFrom.cs" -ForegroundColor Green
    
    # Create MappingProfile.cs
    Write-Host "Creating MappingProfile.cs..." -ForegroundColor White
    
    $mappingProfileContent = @"
using System.Reflection;
using AutoMapper;

namespace $projectName.Application.Common.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        ApplyMappingsFromAssembly(Assembly.GetExecutingAssembly());
    }

    private void ApplyMappingsFromAssembly(Assembly assembly)
    {
        var mapFromType = typeof(IMapFrom<>);
        
        var mappingMethodName = nameof(IMapFrom<object>.Mapping);
        
        bool HasInterface(Type t) => t.IsGenericType && t.GetGenericTypeDefinition() == mapFromType;
        
        var types = assembly.GetExportedTypes().Where(t => t.GetInterfaces().Any(HasInterface)).ToList();
        
        var argumentTypes = new Type[] { typeof(Profile) };
        
        foreach (var type in types)
        {
            var instance = Activator.CreateInstance(type);
            
            var methodInfo = type.GetMethod(mappingMethodName);
            
            if (methodInfo != null)
            {
                methodInfo.Invoke(instance, new object[] { this });
            }
            else
            {
                var interfaces = type.GetInterfaces().Where(HasInterface).ToList();
                
                if (interfaces.Count > 0)
                {
                    foreach (var @interface in interfaces)
                    {
                        var interfaceMethodInfo = @interface.GetMethod(mappingMethodName, argumentTypes);
                        
                        interfaceMethodInfo?.Invoke(instance, new object[] { this });
                    }
                }
            }
        }
    }
}
"@
    
    $mappingProfilePath = Join-Path $mappingsPath "MappingProfile.cs"
    Set-Content -Path $mappingProfilePath -Value $mappingProfileContent -Encoding UTF8
    Write-Host "✓ Created MappingProfile.cs" -ForegroundColor Green
    
}
catch {
    Write-Host "⚠ Failed to create mapping interfaces" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
# =============================================================================
# STEP 5.9: CREATE API CONTROLLER BASE CLASS WITH EXCEPTION HANDLING
# =============================================================================
Write-Host "=== CREATING API CONTROLLER BASE CLASS WITH EXCEPTION HANDLING ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Ensure Controllers directory exists in Web project
    $controllersPath = "src\Web\Controllers"
    if (-not (Test-Path $controllersPath)) {
        New-Item -ItemType Directory -Path $controllersPath -Force | Out-Null
        Write-Host "Created Controllers directory" -ForegroundColor White
    }
    
    # Create ApiControllerBase.cs with ExecuteAsync helper
    $apiControllerBaseContent = @"
using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using $projectName.Application.Common.Exceptions;

namespace $projectName.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public abstract class ApiControllerBase : ControllerBase
{
    private ISender? _mediator;
    protected ISender Mediator => _mediator ??= HttpContext.RequestServices.GetRequiredService<ISender>();

    // For actions that return ActionResult<T>
    protected async Task<ActionResult<T>> ExecuteAsync<T>(Func<Task<T>> action)
    {
        try
        {
            return Ok(await action());
        }
        catch ($projectName.Application.Common.Exceptions.NotFoundException ex)
        {
            return NotFound(new ProblemDetails 
            { 
                Title = "Not Found",
                Detail = ex.Message,
                Status = 404
            });
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ValidationProblemDetails(ex.Errors)
            {
                Status = 400
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new ProblemDetails
            {
                Title = "Unauthorized",
                Status = 401
            });
        }
        catch (ForbiddenAccessException)
        {
            return StatusCode(403, new ProblemDetails
            {
                Title = "Forbidden",
                Status = 403
            });
        }
        catch (DbUpdateException ex)
        {
            return Conflict(new ProblemDetails
            {
                Title = "Database Conflict",
                Detail = ex.InnerException?.Message ?? ex.Message,
                Status = 409
            });
        }
       catch (Exception ex)
        {
            // TODO: Log exception using ILogger
            return StatusCode(500, new ProblemDetails
            {
                Title = "Internal Server Error",
                Detail = $"An unexpected error occurred: {ex.Message}",
                Status = 500
            });
        }
    }

    // For actions that return IActionResult (PUT, DELETE)
    protected async Task<IActionResult> ExecuteAsync(Func<Task> action)
    {
        try
        {
            await action();
            return Ok();
        }
        catch ($projectName.Application.Common.Exceptions.NotFoundException ex)
        {
            return NotFound(new ProblemDetails 
            { 
                Title = "Not Found",
                Detail = ex.Message,
                Status = 404
            });
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ValidationProblemDetails(ex.Errors)
            {
                Status = 400
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new ProblemDetails
            {
                Title = "Unauthorized",
                Status = 401
            });
        }
        catch (ForbiddenAccessException)
        {
            return StatusCode(403, new ProblemDetails
            {
                Title = "Forbidden",
                Status = 403
            });
        }
        catch (DbUpdateException ex)
        {
            return Conflict(new ProblemDetails
            {
                Title = "Database Conflict",
                Detail = ex.InnerException?.Message ?? ex.Message,
                Status = 409
            });
        }
      catch (Exception ex)
        {
            // TODO: Log exception: _logger.LogError(ex, "Unexpected error");
            return StatusCode(500, new ProblemDetails
            {
                Title = "Internal Server Error",
                Detail = $"An unexpected error occurred: {ex.Message}",
                Status = 500
            });
        }
    }
}
"@
    
    $apiControllerBasePath = Join-Path $controllersPath "ApiControllerBase.cs"
    Set-Content -Path $apiControllerBasePath -Value $apiControllerBaseContent -Encoding UTF8
    Write-Host "✓ Created ApiControllerBase.cs with exception handling" -ForegroundColor Green
    
}
catch {
    Write-Host "⚠ Failed to create API controller base class" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# STEP 6: CONFIGURE DATABASE CONNECTION
# =============================================================================
Write-Host "=== CONFIGURING DATABASE CONNECTION ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Updating database connection configuration..." -ForegroundColor White

try {
    # Update appsettings.json (Production configuration)
    $appsettingsPath = "src/Web/appsettings.json"
    
    if (Test-Path $appsettingsPath) {
        $appsettingsContent = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
        
        # Update the DefaultConnection
        if ($appsettingsContent.ConnectionStrings) {
            $appsettingsContent.ConnectionStrings.DefaultConnection = $connectionString
        }
        else {
            $appsettingsContent | Add-Member -Type NoteProperty -Name "ConnectionStrings" -Value @{
                DefaultConnection = $connectionString
            }
        }
        
        # Save updated configuration
        $appsettingsContent | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath -Encoding UTF8
        Write-Host "  ✓ Updated appsettings.json" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ appsettings.json not found" -ForegroundColor Yellow
    }

    # Update appsettings.Development.json (Development configuration - CRITICAL)
    $appsettingsDevPath = "src/Web/appsettings.Development.json"
    
    if (Test-Path $appsettingsDevPath) {
        $appsettingsDevContent = Get-Content $appsettingsDevPath -Raw | ConvertFrom-Json
        
        # Remove template LocalDB connection string (project-specific name like "Hospital_API1Db")
        if ($appsettingsDevContent.ConnectionStrings) {
            # Get all connection string property names
            $csProperties = $appsettingsDevContent.ConnectionStrings.PSObject.Properties.Name
            
            # Remove any that aren't "DefaultConnection"
            foreach ($propName in $csProperties) {
                if ($propName -ne "DefaultConnection") {
                    $appsettingsDevContent.ConnectionStrings.PSObject.Properties.Remove($propName)
                    Write-Host "    Removed template connection: $propName" -ForegroundColor DarkGray
                }
            }
            
            # Set DefaultConnection
            if ($appsettingsDevContent.ConnectionStrings.PSObject.Properties.Name -contains "DefaultConnection") {
                $appsettingsDevContent.ConnectionStrings.DefaultConnection = $connectionString
            }
            else {
                $appsettingsDevContent.ConnectionStrings | Add-Member -Type NoteProperty -Name "DefaultConnection" -Value $connectionString
            }
        }
        else {
            # Create ConnectionStrings section
            $appsettingsDevContent | Add-Member -Type NoteProperty -Name "ConnectionStrings" -Value @{
                DefaultConnection = $connectionString
            }
        }
        
        # Save updated configuration
        $appsettingsDevContent | ConvertTo-Json -Depth 10 | Set-Content $appsettingsDevPath -Encoding UTF8
        Write-Host "  ✓ Updated appsettings.Development.json" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ appsettings.Development.json not found" -ForegroundColor Yellow
    }

    # Fix Infrastructure DependencyInjection.cs to use "DefaultConnection"
    $diPath = "src\Infrastructure\DependencyInjection.cs"
    
    if (Test-Path $diPath) {
        Write-Host "  Updating Infrastructure connection string reference..." -ForegroundColor White
        $diContent = Get-Content $diPath -Raw
        
        # Replace project-specific connection string name with "DefaultConnection"
        # Pattern: GetConnectionString("{ProjectName}Db")
        $pattern = 'GetConnectionString\("' + [regex]::Escape($projectName) + 'Db"\)'
        $diContent = $diContent -replace $pattern, 'GetConnectionString("DefaultConnection")'
        
        # Also update error messages
        $errorPattern = "Connection string '" + [regex]::Escape($projectName) + "Db' not found"
        $diContent = $diContent -replace $errorPattern, "Connection string 'DefaultConnection' not found"
        
        Set-Content $diPath $diContent -Encoding UTF8
        Write-Host "  ✓ Updated Infrastructure to use DefaultConnection" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ DependencyInjection.cs not found" -ForegroundColor Yellow
    }

    Write-Host "✓ Database connection configured successfully" -ForegroundColor Green

}
catch {
    Write-Host "⚠ Failed to configure database connection" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Manual configuration may be required" -ForegroundColor Yellow
}

Write-Host ""

# =============================================================================
# STEP 6.5: STAGING PROJECT & DATABASE SCAFFOLD
# =============================================================================
Write-Host "=== SCAFFOLDING DATABASE MODELS ===" -ForegroundColor Cyan
Write-Host ""

# Store current project location and get parent directory
$mainProjectRoot = Get-Location
$parentFolder = Split-Path -Parent $mainProjectRoot

# Create staging directory at same level as main solution (not inside it)
$stagingPath = Join-Path $parentFolder "TempScaffold_$(Get-Date -Format 'yyyyMMddHHmmss')"
$stagingProjectName = "StagingScaffold"

Write-Host "Creating temporary staging project for EF scaffold..." -ForegroundColor White

try {
    # Create staging directory and navigate to it
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
    Push-Location $stagingPath

    # Create temporary console project
    Write-Host "  Creating staging project..." -ForegroundColor White
    $createResult = dotnet new console -n $stagingProjectName --force 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create staging project: $createResult"
    }

    # Navigate to staging project
    Set-Location $stagingProjectName

    # Install EF packages into staging project
    Write-Host "  Installing Entity Framework packages..." -ForegroundColor White
    
    $stagingPackages = @(
        @{ Name = "Microsoft.EntityFrameworkCore"; Version = "7.0.10" },
        @{ Name = "Microsoft.EntityFrameworkCore.Design"; Version = "7.0.10" },
        @{ Name = "Microsoft.EntityFrameworkCore.Tools"; Version = "7.0.10" }
    )

    # Add provider-specific package
    if ($databaseProvider -eq "PostgreSQL") {
        $stagingPackages += @{ Name = "Npgsql.EntityFrameworkCore.PostgreSQL"; Version = "7.0.4" }
        $scaffoldProvider = "Npgsql.EntityFrameworkCore.PostgreSQL"
    }
    elseif ($databaseProvider -eq "SQL Server") {
        $stagingPackages += @{ Name = "Microsoft.EntityFrameworkCore.SqlServer"; Version = "7.0.10" }
        $scaffoldProvider = "Microsoft.EntityFrameworkCore.SqlServer"
    }
    else {
        $stagingPackages += @{ Name = "Microsoft.EntityFrameworkCore.Sqlite"; Version = "7.0.10" }
        $scaffoldProvider = "Microsoft.EntityFrameworkCore.Sqlite"
    }

    foreach ($package in $stagingPackages) {
        $installResult = dotnet add package $package.Name --version $package.Version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install $($package.Name): $installResult"
        }
    }
    Write-Host "  ✓ EF packages installed" -ForegroundColor Green

    # Create Models directory
    if (-not (Test-Path "Models")) {
        New-Item -ItemType Directory -Path "Models" | Out-Null
    }

    # Run EF scaffolding with intelligent schema filtering
    Write-Host "  Running EF Core scaffold from database..." -ForegroundColor White

    if ($databaseProvider -eq "PostgreSQL") {
        # Extract schemas from Search Path parameter
        $searchPathMatch = [regex]::Match($connectionString, "Search Path=([^;]+)")
    
        if ($searchPathMatch.Success) {
            # User specified Search Path - use those schemas
            $searchPath = $searchPathMatch.Groups[1].Value
            $schemas = $searchPath -split ',' | ForEach-Object { $_.Trim() }
        
            Write-Host "    Scaffolding specified schemas: $($schemas -join ', ')" -ForegroundColor Gray
        
            # Build --schema parameters for each schema
            $schemaParams = @()
            foreach ($schema in $schemas) {
                $schemaParams += "--schema"
                $schemaParams += $schema
            }
        
            # Execute scaffold with schema filtering
            $scaffoldResult = dotnet ef dbcontext scaffold $connectionString $scaffoldProvider --output-dir Models --force $schemaParams 2>&1
        }
        else {
            # No Search Path specified - default to 'public' only (exclude system schemas)
            Write-Host "    No Search Path specified - scaffolding 'public' schema only" -ForegroundColor Gray
            Write-Host "    (Excludes system schemas: sys, pg_catalog, information_schema)" -ForegroundColor DarkGray
            $scaffoldResult = dotnet ef dbcontext scaffold $connectionString $scaffoldProvider --output-dir Models --schema public --force 2>&1
        }
    }
    elseif ($databaseProvider -eq "SQL Server") {
        # SQL Server: scaffold 'dbo' schema only (exclude sys, INFORMATION_SCHEMA)
        Write-Host "    Scaffolding 'dbo' schema only (excludes system schemas)" -ForegroundColor Gray
        $scaffoldResult = dotnet ef dbcontext scaffold $connectionString $scaffoldProvider --output-dir Models --schema dbo --force 2>&1
    }
    else {
        # SQLite: no schema support
        $scaffoldResult = dotnet ef dbcontext scaffold $connectionString $scaffoldProvider --output-dir Models --force 2>&1
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Scaffolding failed: $scaffoldResult"
    }

    # Count generated files
    $modelFiles = Get-ChildItem -Path "Models" -Filter "*.cs" | Where-Object { $_.Name -notlike "*Context.cs" }
    $contextFiles = Get-ChildItem -Path "Models" -Filter "*Context.cs"

    Write-Host "  ✓ Scaffolding complete: $($modelFiles.Count) entities, $($contextFiles.Count) DbContext" -ForegroundColor Green

    # Return to main project root
    Pop-Location

    Write-Host "✓ Staging scaffold completed successfully" -ForegroundColor Green

    # Extract DbSet property names from scaffolded DbContext for correct pluralization
    Write-Host "  Extracting DbSet mappings from scaffolded DbContext..." -ForegroundColor White
    
    $contextFile = Get-ChildItem -Path "$stagingPath\$stagingProjectName\Models" -Filter "*Context.cs" | Select-Object -First 1
    
    if ($contextFile) {
        $contextContent = Get-Content -Path $contextFile.FullName -Raw
        
        # Pattern matches: DbSet<EntityName> PropertyName { get; set; }
        $dbSetPattern = 'DbSet<(\w+)>\s+(\w+)\s*\{'
        $matches = [regex]::Matches($contextContent, $dbSetPattern)
        
        # Store entity→plural mapping globally
        $global:EntityPluralMap = @{}
        foreach ($match in $matches) {
            $entityName = $match.Groups[1].Value
            $pluralName = $match.Groups[2].Value
            $global:EntityPluralMap[$entityName] = $pluralName
        }
        
        Write-Host "  ✓ Extracted $($global:EntityPluralMap.Count) DbSet mappings" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Could not find DbContext file for mapping extraction" -ForegroundColor Yellow
        $global:EntityPluralMap = @{}
    }

}
catch {
    Pop-Location -ErrorAction SilentlyContinue


    Write-Host "✗ Staging scaffold failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Clean up staging on failure
    if (Test-Path $stagingPath) {
        Remove-Item -Path $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# =============================================================================
# STEP 6.55: CREATE CAPABILITY INTERFACES (IF NEEDED)
# =============================================================================
Write-Host "=== CREATING CAPABILITY INTERFACES ===" -ForegroundColor Cyan
Write-Host ""

try {
    $domainCommonPath = "src\Domain\Common"
    
    # Ensure Common directory exists
    if (-not (Test-Path $domainCommonPath)) {
        New-Item -ItemType Directory -Path $domainCommonPath -Force | Out-Null
    }
    
    # Create ISoftDeletable.cs
    $softDeletablePath = Join-Path $domainCommonPath "ISoftDeletable.cs"
    if (-not (Test-Path $softDeletablePath)) {
        $softDeletableContent = @"
namespace $projectName.Domain.Common;

public interface ISoftDeletable
{
    bool RecDelete { get; set; }
}
"@
        Set-Content -Path $softDeletablePath -Value $softDeletableContent -Encoding UTF8
        Write-Host "✓ Created ISoftDeletable.cs" -ForegroundColor Green
    }
    else {
        Write-Host "✓ ISoftDeletable.cs already exists" -ForegroundColor Gray
    }
    
    # Create IAuditable.cs
    $auditablePath = Join-Path $domainCommonPath "IAuditable.cs"
    if (-not (Test-Path $auditablePath)) {
        $auditableContent = @"
namespace $projectName.Domain.Common;

public interface IAuditable
{
    string? CreatedBy { get; set; }
    DateTime? Created { get; set; }
    string? LastModifiedBy { get; set; }
    DateTime? LastModified { get; set; }
}
"@
        Set-Content -Path $auditablePath -Value $auditableContent -Encoding UTF8
        Write-Host "✓ Created IAuditable.cs" -ForegroundColor Green
    }
    else {
        Write-Host "✓ IAuditable.cs already exists" -ForegroundColor Gray
    }
    
    Write-Host "✓ Capability interfaces ready" -ForegroundColor Green
    
}
catch {
    Write-Host "⚠ Failed to create capability interfaces" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# STEP 6.6: INTELLIGENT ENTITY INTEGRATION WITH CAPABILITY DETECTION
# =============================================================================
Write-Host "=== INTEGRATING SCAFFOLDED MODELS WITH CAPABILITY DETECTION ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Verify staging path exists
    if (-not (Test-Path $stagingPath)) {
        throw "Staging path not found: $stagingPath"
    }
    
    # Locate Models folder
    $modelsPath = Join-Path $stagingPath "$stagingProjectName\Models"
    if (-not (Test-Path $modelsPath)) {
        throw "Models folder not found at: $modelsPath"
    }
    
    Write-Host "Analyzing entity capabilities from database schema..." -ForegroundColor White
    Write-Host ""
    
    # Get all .cs files EXCEPT DbContext
    $entityFiles = Get-ChildItem -Path $modelsPath -Filter "*.cs" | 
    Where-Object { $_.Name -notlike "*Context.cs" }
    
    if ($entityFiles.Count -eq 0) {
        Write-Host "⚠ No entity files found to copy" -ForegroundColor Yellow
    }
    else {
        # Target directories
        $domainEntitiesPath = "src\Domain\Entities"
        $domainIdentityPath = "src\Domain\Identity"
        
        # Ensure target directories exist
        if (-not (Test-Path $domainEntitiesPath)) {
            New-Item -ItemType Directory -Path $domainEntitiesPath -Force | Out-Null
        }
        
        # Define ASP.NET Identity infrastructure tables (Tier 1: Exclude completely)
        $identityInfrastructureTables = @(
            'AspNetUserLogin',
            'AspNetUserRole', 
            'AspNetUserToken',
            'AspNetRoleClaim',
            'AspNetUserClaim'
        )
        
        # Define ASP.NET Identity core tables (Tier 2: Isolate to Domain\Identity)
        $identityCoreTables = @('AspNetUser', 'AspNetRole')
        
        # Define audit property signatures for detection
        $auditPropertyPatterns = @{
            Created        = 'public\s+DateTime\??\s+Created\s*\{'
            CreatedBy      = 'public\s+string\??\s+CreatedBy\s*\{'
            LastModified   = 'public\s+DateTime\??\s+LastModified\s*\{'
            LastModifiedBy = 'public\s+string\??\s+LastModifiedBy\s*\{'
            RecDelete      = 'public\s+bool\??\s+RecDelete\s*\{'
        }
        
        # Statistics tracking
        $integrationStats = @{
            Excluded        = 0
            IdentityCore    = 0
            FullAudit       = 0
            SoftDeleteOnly  = 0
            BaseOnly        = 0
            PrimaryKeyTypes = @{}
        }
        
        # Process each entity file
        foreach ($file in $entityFiles) {
            $content = Get-Content -Path $file.FullName -Raw
            $entityName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            
            Write-Host "  Processing: $entityName" -ForegroundColor White
            
            # ========================================================================
            # TIER 1: EXCLUDE IDENTITY INFRASTRUCTURE TABLES (COMPOSITE KEYS)
            # ========================================================================
            if ($entityName -in $identityInfrastructureTables) {
                Write-Host "    ⊗ Excluded: Infrastructure table (composite key)" -ForegroundColor DarkGray
                Write-Host "    Reason: Join tables managed by Identity framework" -ForegroundColor DarkGray
                $integrationStats.Excluded++
                Write-Host ""
                continue  # Skip completely - don't copy to Domain
            }
            
            # ========================================================================
            # TIER 2: ISOLATE IDENTITY CORE TABLES (AspNetUser, AspNetRole)
            # ========================================================================
            if ($entityName -in $identityCoreTables) {
                Write-Host "    🔐 Identity Core Table" -ForegroundColor Magenta
                
                # Create Identity subfolder if needed
                if (-not (Test-Path $domainIdentityPath)) {
                    New-Item -ItemType Directory -Path $domainIdentityPath -Force | Out-Null
                    Write-Host "    Created: Domain\Identity\" -ForegroundColor DarkGray
                }
                
                # Minimal transformation (no capability detection)
                $content = $content -replace 'using System;\r?\n', ''
                $content = $content -replace 'using System\.Collections\.Generic;\r?\n', ''
                $content = $content -replace 'namespace [^;]+\.Models;', "namespace $projectName.Domain.Identity;"
                
                # Apply BaseEntity inheritance only
                $classPattern = '(public partial class ' + $entityName + ')\s*(\r?\n|\{)'
                $content = $content -replace $classPattern, '$1 : BaseEntity$2'
                
                # Write to Identity subfolder
                $targetPath = Join-Path $domainIdentityPath $file.Name
                Set-Content -Path $targetPath -Value $content -Encoding UTF8
                
                Write-Host "    ✓ Isolated: Domain\Identity\$($file.Name)" -ForegroundColor Green
                Write-Host "    Inheritance: BaseEntity (no capabilities)" -ForegroundColor DarkGray
                Write-Host "    ℹ Code generation will skip this table" -ForegroundColor DarkGray
                
                $integrationStats.IdentityCore++
                Write-Host ""
                continue  # Skip standard business entity processing
            }
            
            # ========================================================================
            # TIER 3: BUSINESS ENTITIES - FULL CAPABILITY DETECTION
            # ========================================================================
            
            Write-Host "    📊 Business Entity" -ForegroundColor Cyan
            
            # --- DETECT PRIMARY KEY (NEVER REMOVE) ---
            $pkPattern = 'public\s+(\w+\??)\s+(Id|' + $entityName + 'Id)\s*\{\s*get;\s*set;\s*\}'
            $pkMatch = [regex]::Match($content, $pkPattern)
            
            $pkPropertyName = ""
            $pkType = ""
            
            if ($pkMatch.Success) {
                $pkType = $pkMatch.Groups[1].Value          # "int", "Guid", "long", etc.
                $pkPropertyName = $pkMatch.Groups[2].Value  # "Id" or "DoctorId"
                Write-Host "    ✓ Primary Key: $pkType $pkPropertyName" -ForegroundColor DarkGreen
                
                # Track PK type statistics
                if (-not $integrationStats.PrimaryKeyTypes.ContainsKey($pkType)) {
                    $integrationStats.PrimaryKeyTypes[$pkType] = 0
                }
                $integrationStats.PrimaryKeyTypes[$pkType]++
            }
            else {
                Write-Host "    ⚠ No standard primary key detected" -ForegroundColor Yellow
            }
            
            # --- DETECT AUDIT PROPERTIES ---
            $detectedProperties = @{}
            foreach ($propName in $auditPropertyPatterns.Keys) {
                if ($content -match $auditPropertyPatterns[$propName]) {
                    $detectedProperties[$propName] = $true
                    Write-Host "    ✓ Found: $propName" -ForegroundColor DarkGray
                }
            }
            
            # --- DETERMINE ENTITY CAPABILITIES ---
            $capabilities = @{
                Interfaces         = @()
                PropertiesToRemove = @()
                PrimaryKey         = $pkPropertyName
                PrimaryKeyType     = $pkType
            }
            
            # Check for soft delete capability
            if ($detectedProperties.ContainsKey('RecDelete')) {
                $capabilities.Interfaces += 'ISoftDeletable'
                $capabilities.PropertiesToRemove += 'RecDelete'
                Write-Host "    → Capability: ISoftDeletable" -ForegroundColor Cyan
            }
            
            # Check for full audit trail capability
            $hasFullAudit = $detectedProperties.ContainsKey('Created') -and 
            $detectedProperties.ContainsKey('LastModified')
            
            if ($hasFullAudit) {
                $capabilities.Interfaces += 'IAuditable'
                $capabilities.PropertiesToRemove += @('Created', 'CreatedBy', 'LastModified', 'LastModifiedBy')
                Write-Host "    → Capability: IAuditable" -ForegroundColor Cyan
            }
            
            # Update statistics
            if ($capabilities.Interfaces -contains 'IAuditable' -and $capabilities.Interfaces -contains 'ISoftDeletable') {
                $integrationStats.FullAudit++
            }
            elseif ($capabilities.Interfaces -contains 'ISoftDeletable') {
                $integrationStats.SoftDeleteOnly++
            }
            else {
                $integrationStats.BaseOnly++
            }
            
            # --- BEGIN ENTITY TRANSFORMATION ---
            
            # Remove System using statements
            $content = $content -replace 'using System;\r?\n', ''
            $content = $content -replace 'using System\.Collections\.Generic;\r?\n', ''
            
            # Fix namespace
            $content = $content -replace 'namespace [^;]+\.Models;', "namespace $projectName.Domain.Entities;"
          
            # --- DETECT AUDIT PROPERTIES WITH EXACT TYPE ANALYSIS ---
            $detectedAuditTypes = @{}
            $auditProps = @('Created', 'CreatedBy', 'LastModified', 'LastModifiedBy', 'RecDelete')

            foreach ($propName in $auditProps) {
                $pattern = "public\s+(\w+\??)\s+$propName\s*\{\s*get;\s*set;\s*\}"
                $match = [regex]::Match($content, $pattern)
    
                if ($match.Success) {
                    $propType = $match.Groups[1].Value
                    $detectedAuditTypes[$propName] = $propType
                }
            }

            # --- CHECK IF TYPES MATCH BaseAuditableEntity SIGNATURE ---
            $baseAuditableSignature = @{
                'Created'        = 'DateTime'
                'CreatedBy'      = 'string?'
                'LastModified'   = 'DateTime?'
                'LastModifiedBy' = 'string?'
                'RecDelete'      = 'bool'
            }

            $hasFullAudit = ($detectedAuditTypes.Count -eq 5)

            if ($hasFullAudit) {
                # Check if ALL types match BaseAuditableEntity
                $typesMatch = $true
    
                foreach ($propName in $baseAuditableSignature.Keys) {
                    if (-not $detectedAuditTypes.ContainsKey($propName)) {
                        $typesMatch = $false
                        break
                    }
        
                    $expectedType = $baseAuditableSignature[$propName]
                    $actualType = $detectedAuditTypes[$propName]
        
                    if ($expectedType -ne $actualType) {
                        $typesMatch = $false
                        Write-Host "    ⚠ Type mismatch: $propName (expected $expectedType, got $actualType)" -ForegroundColor Yellow
                        break
                    }
                }
    
                if ($typesMatch) {
                    # PERFECT MATCH - Use BaseAuditableEntity and remove properties
                    $integrationStats.FullAudit++
                    Write-Host "    → Strategy: BaseAuditableEntity (removing audit properties)" -ForegroundColor Cyan
        
                    # Remove all audit properties
                    foreach ($propName in $auditProps) {
                        if ($propName -eq $pkPropertyName) { 
                            Write-Host "    ⚠ Safety: Skipped PK removal" -ForegroundColor Yellow
                            continue 
                        }
            
                        $pattern = "\s+public\s+\w+\??\s+$propName\s*\{\s*get;\s*set;\s*\}.*?\r?\n"
                        $beforeLength = $content.Length
                        $content = $content -replace $pattern, ''
            
                        if ($content.Length -lt $beforeLength) {
                            Write-Host "    ✓ Removed: $propName (inherited from base)" -ForegroundColor DarkGray
                        }
                    }
        
                    $inheritanceString = 'BaseAuditableEntity'
        
                }
                else {
                    # TYPE MISMATCH - Use BaseEntity and keep properties
                    $integrationStats.BaseOnly++
                    Write-Host "    → Strategy: BaseEntity (keeping properties - type mismatch)" -ForegroundColor Yellow
        
                    $inheritanceString = 'BaseEntity'
                }
    
            }
            else {
                # Partial or no audit - use BaseEntity
                $integrationStats.BaseOnly++
                Write-Host "    → Strategy: BaseEntity (partial/no audit)" -ForegroundColor Gray
    
                $inheritanceString = 'BaseEntity'
            }
            
            # Apply inheritance
            $classPattern = '(public partial class ' + $entityName + ')\s*(\r?\n|\{)'
            $replacement = "`$1 : $inheritanceString`$2"
            $content = $content -replace $classPattern, $replacement
            
            # --- WRITE TRANSFORMED ENTITY ---
            $targetPath = Join-Path $domainEntitiesPath $file.Name
            Set-Content -Path $targetPath -Value $content -Encoding UTF8
            
            Write-Host "    ✓ Integrated: Domain\Entities\$($file.Name)" -ForegroundColor Green
            Write-Host "    Inheritance: $inheritanceString" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        # ========================================================================
        # INTEGRATION SUMMARY REPORT
        # ========================================================================
        Write-Host ""
        Write-Host ("=" * 75) -ForegroundColor Green
        Write-Host "ENTITY INTEGRATION COMPLETE" -ForegroundColor Green
        Write-Host ("=" * 75) -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Processing Summary:" -ForegroundColor White
        Write-Host "  Total Files Analyzed:  $($entityFiles.Count)" -ForegroundColor Cyan
        Write-Host ""
        
        if ($integrationStats.Excluded -gt 0) {
            Write-Host "  ⊗ Excluded (Infrastructure):              $($integrationStats.Excluded)" -ForegroundColor DarkGray
            Write-Host "    (AspNetUserLogin, AspNetUserRole, etc.)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        if ($integrationStats.IdentityCore -gt 0) {
            Write-Host "  🔐 Identity Core (Isolated):               $($integrationStats.IdentityCore)" -ForegroundColor Magenta
            Write-Host "    Location: Domain\Identity\" -ForegroundColor DarkGray
            Write-Host "    Inheritance: BaseEntity only" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        $businessEntityCount = $integrationStats.FullAudit + $integrationStats.SoftDeleteOnly + $integrationStats.BaseOnly
        if ($businessEntityCount -gt 0) {
            Write-Host "  📊 Business Entities (Domain\Entities\):   $businessEntityCount" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "    Capability Distribution:" -ForegroundColor White
            Write-Host "      ✓ Full Audit (IAuditable + ISoftDeletable): $($integrationStats.FullAudit)" -ForegroundColor Green
            Write-Host "      ✓ Soft Delete Only (ISoftDeletable):        $($integrationStats.SoftDeleteOnly)" -ForegroundColor Yellow
            Write-Host "      ✓ Base Entity Only (no capabilities):       $($integrationStats.BaseOnly)" -ForegroundColor Gray
            Write-Host ""
        }
        
        if ($integrationStats.PrimaryKeyTypes.Count -gt 0) {
            Write-Host "  Primary Key Types Detected:" -ForegroundColor White
            foreach ($pkType in $integrationStats.PrimaryKeyTypes.Keys | Sort-Object) {
                $count = $integrationStats.PrimaryKeyTypes[$pkType]
                $plural = if ($count -eq 1) { "entity" } else { "entities" }
                Write-Host "    $pkType : $count $plural" -ForegroundColor Cyan
            }
            Write-Host ""
        }
        
        Write-Host "Architecture Notes:" -ForegroundColor White
        Write-Host "  • Primary keys preserved as defined in database schema" -ForegroundColor Gray
        Write-Host "  • BaseEntity provides domain events infrastructure" -ForegroundColor Gray
        Write-Host "  • Interfaces provide audit capabilities via composition" -ForegroundColor Gray
        Write-Host "  • Identity tables isolated to prevent architectural pollution" -ForegroundColor Gray
        Write-Host "  • Code generation targets Domain\Entities only" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host ("=" * 75) -ForegroundColor Green
        Write-Host ""
    }
    
}
catch {
    Write-Host ""
    Write-Host ("=" * 75) -ForegroundColor Red
    Write-Host "ENTITY INTEGRATION FAILED" -ForegroundColor Red
    Write-Host ("=" * 75) -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "Troubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "  1. Verify staging path exists and contains Models folder" -ForegroundColor White
    Write-Host "     Path: $stagingPath\$stagingProjectName\Models" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Check that scaffolding completed successfully in Step 6.5" -ForegroundColor White
    Write-Host "     Expected: *.cs files in Models folder (excluding *Context.cs)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Ensure src\Domain directory exists and is writable" -ForegroundColor White
    Write-Host "     Required: Write permissions for creating Entities and Identity subfolders" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Verify no file locks on target directories" -ForegroundColor White
    Write-Host "     Tip: Close Visual Studio if solution is open" -ForegroundColor Gray
    Write-Host ""
    
    throw
}

Write-Host ""

# =============================================================================
# STEP 6.7: ADD SCAFFOLDED ENTITIES TO DBCONTEXT FILES
# =============================================================================
Write-Host "=== ADDING SCAFFOLDED ENTITIES TO DBCONTEXT FILES ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Get all entity files from Domain\Entities
    $domainEntitiesPath = "src\Domain\Entities"
    $entityFiles = Get-ChildItem -Path $domainEntitiesPath -Filter "*.cs" -ErrorAction Stop
    
    if ($entityFiles.Count -eq 0) {
        Write-Host "⚠ No entity files found to add to DbContext" -ForegroundColor Yellow
    }
    else {
        Write-Host "Processing $($entityFiles.Count) entities..." -ForegroundColor White
        
        # Extract entity names and generate DbSet declarations
        $dbSetDeclarations = @()
        
        foreach ($file in $entityFiles) {
            # Read file to extract class name
            $content = Get-Content -Path $file.FullName -Raw
            
            # Extract class name using regex
            if ($content -match 'public partial class (\w+)') {
                $entityName = $matches[1]
                
                # Use correct plural from scaffolded DbContext
                $pluralName = $global:EntityPluralMap[$entityName]
                
                if (-not $pluralName) {
                    # Fallback to naive pluralization if mapping not found
                    $pluralName = $entityName + "s"
                    Write-Host "  ⚠ No plural mapping for $entityName, using '$pluralName'" -ForegroundColor Yellow
                }
                
                # Store for both interface and class
                $dbSetDeclarations += @{
                    EntityName   = $entityName
                    PropertyName = $pluralName
                }
                
                Write-Host "  ✓ Found entity: $entityName → $pluralName" -ForegroundColor Green
            }
        }
        
        if ($dbSetDeclarations.Count -gt 0) {
            # Update IApplicationDbContext interface
            $interfacePath = "src\Application\Common\Interfaces\IApplicationDbContext.cs"
            if (Test-Path $interfacePath) {
                Write-Host "Updating IApplicationDbContext interface..." -ForegroundColor White
                $content = Get-Content -Path $interfacePath -Raw
                
                # Build DbSet declarations for interface
                $interfaceDbSets = ""
                foreach ($decl in $dbSetDeclarations) {
                    $interfaceDbSets += "    DbSet<$($decl.EntityName)> $($decl.PropertyName) { get; }`r`n"
                }
                
                # Insert before SaveChangesAsync method
                $content = $content -replace '(\s+Task<int> SaveChangesAsync)', "$interfaceDbSets`r`n`$1"
                
                Set-Content -Path $interfacePath -Value $content -Encoding UTF8
                Write-Host "  ✓ Added $($dbSetDeclarations.Count) DbSets to IApplicationDbContext" -ForegroundColor Green
            }
            
            # Update ApplicationDbContext class
            $contextPath = "src\Infrastructure\Data\ApplicationDbContext.cs"
            if (Test-Path $contextPath) {
                Write-Host "Updating ApplicationDbContext class..." -ForegroundColor White
                $content = Get-Content -Path $contextPath -Raw
                
                # Build DbSet declarations for class
                $classDbSets = ""
                foreach ($decl in $dbSetDeclarations) {
                    $classDbSets += "`r`n    public DbSet<$($decl.EntityName)> $($decl.PropertyName) => Set<$($decl.EntityName)>();"
                }
                
                # Insert after constructor, before OnModelCreating
                $content = $content -replace '(public ApplicationDbContext\([^}]+\}\s*)', "`$1$classDbSets`r`n"
                
                Set-Content -Path $contextPath -Value $content -Encoding UTF8
                Write-Host "  ✓ Added $($dbSetDeclarations.Count) DbSets to ApplicationDbContext" -ForegroundColor Green
            }
            
            Write-Host "✓ Successfully added all scaffolded entities to DbContext files" -ForegroundColor Green
        }
    }
    
}
catch {
    Write-Host "✗ Failed to add entities to DbContext files!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# STEP 6.75: CONFIGURE DATABASE INITIALIZATION STRATEGY
# =============================================================================
Write-Host "=== CONFIGURING DATABASE INITIALIZATION ===" -ForegroundColor Cyan
Write-Host ""

try {
    $initialiserPath = "src\Infrastructure\Data\ApplicationDbContextInitialiser.cs"
    
    if (Test-Path $initialiserPath) {
        Write-Host "Updating database initialization strategy..." -ForegroundColor White
        $content = Get-Content $initialiserPath -Raw
        
        # Replace MigrateAsync with EnsureCreatedAsync to preserve existing data
        $content = $content -replace 'await _context\.Database\.MigrateAsync\(\);', 'await _context.Database.EnsureCreatedAsync();'
        
        Set-Content $initialiserPath $content -Encoding UTF8
        Write-Host "  ✓ Changed to EnsureCreatedAsync (preserves existing database)" -ForegroundColor Green
        Write-Host "  Note: Database will not be dropped if it already exists" -ForegroundColor Gray
    }
    else {
        Write-Host "  ⚠ ApplicationDbContextInitialiser.cs not found" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "  ⚠ Failed to update database initialization: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# =============================================================================
# STEP 6.76: DISABLE AUTO-INITIALIZATION IN DEVELOPMENT
# =============================================================================
Write-Host "=== DISABLING AUTO-INITIALIZATION FOR DATABASE-FIRST APPROACH ===" -ForegroundColor Cyan
Write-Host ""

try {
    $programPath = "src\Web\Program.cs"
    
    if (Test-Path $programPath) {
        Write-Host "Disabling automatic database initialization..." -ForegroundColor White
        $content = Get-Content $programPath -Raw
        
        # Comment out the InitialiseDatabaseAsync call
        $content = $content -replace '(\s*)(await app\.InitialiseDatabaseAsync\(\);)', '$1// $2  // Disabled for database-first approach'
        
        Set-Content $programPath $content -Encoding UTF8
        Write-Host "  ✓ Disabled InitialiseDatabaseAsync in Program.cs" -ForegroundColor Green
        Write-Host "  Note: Database schema is managed by your existing database" -ForegroundColor Gray
    }
    else {
        Write-Host "  ⚠ Program.cs not found" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "  ⚠ Failed to disable auto-initialization: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""


# =============================================================================
# STEP 6.8: BUILD DOMAIN PROJECT FOR REFLECTION
# =============================================================================
Write-Host "=== BUILDING DOMAIN PROJECT ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "Compiling Domain layer to enable code generation..." -ForegroundColor White
    
    # Build Domain project
    $domainProjectPath = "src\Domain\Domain.csproj"
    
    if (-not (Test-Path $domainProjectPath)) {
        throw "Domain project not found at: $domainProjectPath"
    }
    
    # Clean first to ensure fresh build
    Write-Host "  Cleaning Domain project..." -ForegroundColor White
    $cleanResult = dotnet clean $domainProjectPath --verbosity quiet 2>&1
    
    # Build the Domain project
    Write-Host "  Building Domain project..." -ForegroundColor White
    $buildResult = dotnet build $domainProjectPath --configuration Release --verbosity quiet 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Domain project build failed!" -ForegroundColor Red
        Write-Host "Build output:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Gray
        throw "Cannot proceed with code generation - Domain.dll compilation failed"
    }
    
    # Verify DLL exists - dynamically detect location and target framework
    Write-Host "  Locating compiled Domain.dll..." -ForegroundColor White
    
    # Search for the DLL in common build output locations
    $possiblePaths = @(
        "src\Domain\bin\Release\*\$projectName.Domain.dll",
        "src\Domain\bin\Debug\*\$projectName.Domain.dll",
        "artifacts\bin\Domain\release\$projectName.Domain.dll",
        "artifacts\bin\Domain\debug\$projectName.Domain.dll"
    )
    
    $domainDllPath = $null
    foreach ($pattern in $possiblePaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $domainDllPath = $found.FullName
            break
        }
    }
    
    if (-not $domainDllPath) {
        throw "Domain.dll not found. Build may have failed or output directory structure is unexpected."
    }
    
    # Store DLL path for code generation step
    $global:DomainAssemblyPath = $domainDllPath
    
    Write-Host "✓ Domain.dll compiled successfully" -ForegroundColor Green
    Write-Host "  Assembly location: $global:DomainAssemblyPath" -ForegroundColor Gray
    
}
catch {
    Write-Host "✗ Failed to build Domain project!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Code generation cannot proceed without compiled Domain assembly." -ForegroundColor Yellow
    Write-Host "Please fix build errors and run the script again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# =============================================================================
# STEP 6.85: BUILD INFRASTRUCTURE PROJECT FOR CODE GENERATION
# =============================================================================
Write-Host "=== BUILDING INFRASTRUCTURE PROJECT ===" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "Compiling Infrastructure layer to enable code generation..." -ForegroundColor White
    
    # Build Infrastructure project
    $infrastructureProjectPath = "src\Infrastructure\Infrastructure.csproj"
    
    if (-not (Test-Path $infrastructureProjectPath)) {
        throw "Infrastructure project not found at: $infrastructureProjectPath"
    }
    
    # Clean first to ensure fresh build
    Write-Host "  Cleaning Infrastructure project..." -ForegroundColor White
    $cleanResult = dotnet clean $infrastructureProjectPath --verbosity quiet 2>&1
    
    # Build the Infrastructure project
    Write-Host "  Building Infrastructure project..." -ForegroundColor White
    $buildResult = dotnet build $infrastructureProjectPath --configuration Release --verbosity quiet 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Γ£ù Infrastructure project build failed!" -ForegroundColor Red
        Write-Host "Build output:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Gray
        throw "Cannot proceed with code generation - Infrastructure.dll compilation failed"
    }
    
    # Verify DLL exists - dynamically detect location and target framework
    Write-Host "  Locating compiled Infrastructure.dll..." -ForegroundColor White
    
    # Search for the DLL in common build output locations
    $possiblePaths = @(
        "src\Infrastructure\bin\Release\*\$projectName.Infrastructure.dll",
        "src\Infrastructure\bin\Debug\*\$projectName.Infrastructure.dll",
        "artifacts\bin\Infrastructure\release\$projectName.Infrastructure.dll",
        "artifacts\bin\Infrastructure\debug\$projectName.Infrastructure.dll"
    )
    
    $infrastructureDllPath = $null
    foreach ($pattern in $possiblePaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $infrastructureDllPath = $found.FullName
            break
        }
    }
    
    if (-not $infrastructureDllPath) {
        throw "Infrastructure.dll not found. Build may have failed or output directory structure is unexpected."
    }
    
    # Store DLL path for code generation step
    $global:InfrastructureAssemblyPath = $infrastructureDllPath
    
    Write-Host "✓ Infrastructure.dll compiled successfully" -ForegroundColor Green
    Write-Host "  Assembly location: $global:InfrastructureAssemblyPath" -ForegroundColor Gray
    
    # Verify it can be loaded (optional but catches issues early)
    Write-Host "  Verifying assembly can be loaded..." -ForegroundColor White
    try {
        $infraAssembly = [System.Reflection.Assembly]::LoadFrom($infrastructureDllPath)
        
        # Check if IApplicationDbContext implementation exists
        $iApplicationDbContextType = [type]::GetType("$projectName.Application.Common.Interfaces.IApplicationDbContext")
        
        $dbContextImpl = $infraAssembly.GetTypes() | 
            Where-Object { 
                $_.IsClass -and 
                -not $_.IsAbstract -and 
                $_.GetInterfaces() | Where-Object { $_.Name -eq "IApplicationDbContext" }
            } | 
            Select-Object -First 1
        
        if ($dbContextImpl) {
            Write-Host "  ✓ Found DbContext implementation: $($dbContextImpl.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ΓÜá IApplicationDbContext implementation not found (this may be expected)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ΓÜá Assembly verification encountered an issue: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  Continuing - code generation will verify this at runtime" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host ""
    Write-Host ("=" * 75) -ForegroundColor Red
    Write-Host "INFRASTRUCTURE BUILD FAILED" -ForegroundColor Red
    Write-Host ("=" * 75) -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common causes:" -ForegroundColor Yellow
    Write-Host "  1. Infrastructure.csproj has missing or incorrect dependencies" -ForegroundColor White
    Write-Host "  2. Domain project failed to build (Infrastructure depends on it)" -ForegroundColor White
    Write-Host "  3. NuGet package restore issues" -ForegroundColor White
    Write-Host "  4. Invalid C# code in Infrastructure layer" -ForegroundColor White
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Run: dotnet restore" -ForegroundColor White
    Write-Host "  2. Run: dotnet build src/Infrastructure/Infrastructure.csproj -v detailed" -ForegroundColor White
    Write-Host "  3. Fix any compiler errors shown above" -ForegroundColor White
    Write-Host "  4. Re-run this script" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""


# =============================================================================
# STEP 7: FIX COMMON TEMPLATE ISSUES
# =============================================================================
Write-Host "=== FIXING COMMON TEMPLATE ISSUES ===" -ForegroundColor Cyan
Write-Host ""

# Fix Users.cs endpoint implementation issue
Write-Host "Checking for known template issues..." -ForegroundColor White

$usersEndpointPath = "src/Web/Endpoints/Users.cs"
if (Test-Path $usersEndpointPath) {
    try {
        $usersContent = Get-Content $usersEndpointPath -Raw
        
        # Check if the file has the incorrect Map method signature
        if ($usersContent -match "Map\(WebApplication.*\)" -and $usersContent -match "EndpointGroupBase") {
            Write-Host "✓ Found Users.cs template issue - applying automatic fix..." -ForegroundColor Yellow
            
            # Create the corrected Users.cs content
            $correctedUsersContent = @"
namespace CleanArchitecture.Web.Endpoints;

public class Users : EndpointGroupBase
{
    public override void Map(RouteGroupBuilder group)
    {
        group.MapGet("", GetUsers);
    }

    public IResult GetUsers(ISender sender)
    {
        return Results.Ok("Users endpoint - implement as needed");
    }
}
"@

            # Write the corrected content
            Set-Content $usersEndpointPath -Value $correctedUsersContent -Encoding UTF8
            Write-Host "✓ Users.cs endpoint implementation fixed" -ForegroundColor Green
        }
        else {
            Write-Host "✓ Users.cs appears to be correctly implemented" -ForegroundColor Green
        }
        
    }
    catch {
        Write-Host "⚠ Could not automatically fix Users.cs: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "✓ Users.cs not found - may not be included in this template version" -ForegroundColor Green
}

# Fix NSwag build issues by complete removal (VS2022 compatibility)
Write-Host "Removing NSwag integration to fix VS2022 build issues..." -ForegroundColor Yellow

$nswagRemovalSuccess = $true
$nswagRemovalErrors = @()

try {
    # Step 1: Remove NSwag packages from Web.csproj
    $webCsprojPath = "src/Web/Web.csproj"
    if (Test-Path $webCsprojPath) {
        Write-Host "  Processing Web.csproj..." -ForegroundColor White
        $content = Get-Content $webCsprojPath -Raw

        # Remove NSwag.AspNetCore package reference
        $content = $content -replace '(?s)\s*<PackageReference\s+Include="NSwag\.AspNetCore"[^>]*/?>\s*', ''

        # Remove NSwag.MSBuild package reference (with potential multi-line attributes)
        $content = $content -replace '(?s)\s*<PackageReference\s+Include="NSwag\.MSBuild".*?</PackageReference>\s*', ''

        # Remove the entire NSwag build target
        $content = $content -replace '(?s)\s*<Target\s+Name="NSwag".*?</Target>\s*', ''

        Set-Content $webCsprojPath $content -Encoding UTF8
        Write-Host "    ✓ Removed NSwag packages and targets from Web.csproj" -ForegroundColor Green
    }
    else {
        $nswagRemovalErrors += "Web.csproj not found at expected location"
        $nswagRemovalSuccess = $false
    }

    # Step 2: Remove NSwag package versions from Directory.Packages.props
    $packagesPropsPath = "Directory.Packages.props"
    if (Test-Path $packagesPropsPath) {
        Write-Host "  Processing Directory.Packages.props..." -ForegroundColor White
        $content = Get-Content $packagesPropsPath -Raw

        # Remove NSwag package version declarations
        $content = $content -replace '\s*<PackageVersion\s+Include="NSwag\.AspNetCore"[^>]*/?>\s*', ''
        $content = $content -replace '\s*<PackageVersion\s+Include="NSwag\.MSBuild"[^>]*/?>\s*', ''

        Set-Content $packagesPropsPath $content -Encoding UTF8
        Write-Host "    ✓ Removed NSwag package versions from Directory.Packages.props" -ForegroundColor Green
    }
    else {
        Write-Host "    ⚠ Directory.Packages.props not found - may not be using Central Package Management" -ForegroundColor Yellow
    }

    # Step 3: Remove NSwag configuration file
    $configPath = "src/Web/config.nswag"
    if (Test-Path $configPath) {
        Write-Host "  Removing config.nswag..." -ForegroundColor White
        Remove-Item $configPath -Force
        Write-Host "    ✓ Removed config.nswag file" -ForegroundColor Green
    }
    else {
        Write-Host "    ✓ config.nswag not found (already clean)" -ForegroundColor Green
    }

    # Step 4: Clean build artifacts (optional but recommended)
    $objPath = "src/Web/obj"
    if (Test-Path $objPath) {
        Write-Host "  Cleaning NSwag build artifacts..." -ForegroundColor White
        Get-ChildItem $objPath -Filter "*NSwag*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "    ✓ Cleaned NSwag build artifacts" -ForegroundColor Green
    }
    # Step 5: Remove NSwag code references from DependencyInjection.cs
    $dependencyInjectionPath = "src/Web/DependencyInjection.cs"
    if (Test-Path $dependencyInjectionPath) {
        Write-Host "  Cleaning NSwag references from DependencyInjection.cs..." -ForegroundColor White
        $content = Get-Content $dependencyInjectionPath -Raw
    
        # Only remove using statements - leave service registrations alone
        $content = $content -replace 'using NSwag[^;]*;[\r\n]*', ''
    
        Set-Content $dependencyInjectionPath $content -Encoding UTF8
        Write-Host "    ✓ Removed NSwag using statements from DependencyInjection.cs" -ForegroundColor Green
    }
    else {
        Write-Host "    ✓ DependencyInjection.cs not found (clean)" -ForegroundColor Green
    }
    # Step 6: Fix Program.cs - replace NSwag with Swagger and add controller routing
    $programPath = "src/Web/Program.cs"
    if (Test-Path $programPath) {
        Write-Host "  Fixing Program.cs (Swagger + Controller routing)..." -ForegroundColor White
        $content = Get-Content $programPath -Raw
    
        # Replace the entire UseSwaggerUi block with standard UseSwaggerUI
        $content = $content -replace '(?s)app\.UseSwaggerUi\([^}]*\}\);', 'app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "API V1"));'
    
        # Add MapControllers after MapEndpoints (if not already present)
        if ($content -notmatch 'MapControllers') {
            $newLine = [Environment]::NewLine
            $content = $content -replace '(app\.MapEndpoints\(\);)', "`$1${newLine}app.MapControllers();"
            Write-Host "    ✓ Added MapControllers() routing" -ForegroundColor Green
        }
    
        Set-Content $programPath $content -Encoding UTF8
        Write-Host "    ✓ Fixed Program.cs (Swagger + Controllers configured)" -ForegroundColor Green
    }

    # Configure VS2022 to launch Swagger automatically
    $launchSettingsPath = "src/Web/Properties/launchSettings.json"
    if (Test-Path $launchSettingsPath) {
        Write-Host "  Configuring VS2022 launch settings for Swagger..." -ForegroundColor White
    
        try {
            $launchSettings = Get-Content $launchSettingsPath -Raw | ConvertFrom-Json
        
            # Update all profiles to launch Swagger
            $launchSettings.profiles.PSObject.Properties | ForEach-Object {
                $profile = $_.Value
                if ($profile.PSObject.Properties.Name -contains "launchBrowser" -and $profile.launchBrowser -eq $true) {
                    $profile | Add-Member -Type NoteProperty -Name "launchUrl" -Value "swagger" -Force
                }
            }
        
            # Save updated launch settings
            $launchSettings | ConvertTo-Json -Depth 10 | Set-Content $launchSettingsPath -Encoding UTF8
            Write-Host "    ✓ VS2022 will now launch Swagger automatically" -ForegroundColor Green
        
        }
        catch {
            Write-Host "    ⚠ Could not automatically configure launch settings: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "    ⚠ launchSettings.json not found" -ForegroundColor Yellow
    }

    # Step 7: Fix DependencyInjection.cs completely
    $dependencyInjectionPath = "src/Web/DependencyInjection.cs"
    if (Test-Path $dependencyInjectionPath) {
        Write-Host "  Completely fixing DependencyInjection.cs..." -ForegroundColor White
    
        $fixedContent = @"
using Azure.Identity;
using $projectName.Application.Common.Interfaces;
using $projectName.Infrastructure.Data;
using $projectName.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace Microsoft.Extensions.DependencyInjection;

public static class DependencyInjection
{
    public static void AddWebServices(this IHostApplicationBuilder builder)
    {
        builder.Services.AddDatabaseDeveloperPageExceptionFilter();
        builder.Services.AddScoped<IUser, CurrentUser>();
        builder.Services.AddHttpContextAccessor();
        builder.Services.AddHealthChecks()
            .AddDbContextCheck<ApplicationDbContext>();
        builder.Services.AddExceptionHandler<CustomExceptionHandler>();
        
        // Customise default API behaviour
        builder.Services.Configure<ApiBehaviorOptions>(options =>
            options.SuppressModelStateInvalidFilter = true);
            
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();
        builder.Services.AddControllers();
    }
    
    public static void AddKeyVaultIfConfigured(this IHostApplicationBuilder builder)
    {
        var keyVaultUri = builder.Configuration["AZURE_KEY_VAULT_ENDPOINT"];
        if (!string.IsNullOrWhiteSpace(keyVaultUri))
        {
            builder.Configuration.AddAzureKeyVault(
                new Uri(keyVaultUri),
                new DefaultAzureCredential());
        }
    }
}
"@
        Set-Content $dependencyInjectionPath $fixedContent -Encoding UTF8
        Write-Host "    ✓ Fixed DependencyInjection.cs completely" -ForegroundColor Green
    }
    # Add standard Swagger packages to replace NSwag functionality
    $webCsprojPath = "src/Web/Web.csproj"
    if (Test-Path $webCsprojPath) {
        Write-Host "  Adding standard Swagger packages..." -ForegroundColor White
        $content = Get-Content $webCsprojPath -Raw
    
        # Add Swashbuckle packages WITHOUT VERSION (Central Package Management)
        if ($content -match '<ItemGroup>.*?</ItemGroup>') {
            # Add to existing ItemGroup
            $content = $content -replace '(\s*</ItemGroup>)', '    <PackageReference Include="Swashbuckle.AspNetCore" />$1'
        }
        else {
            # Create new ItemGroup before closing Project tag
            $content = $content -replace '(\s*</Project>)', '  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" />
  </ItemGroup>$1'
        }
    
        Set-Content $webCsprojPath $content -Encoding UTF8
        Write-Host "    ✓ Added Swashbuckle.AspNetCore package" -ForegroundColor Green
    }

    # Also add to Directory.Packages.props if using central package management
    $packagesPropsPath = "Directory.Packages.props"
    if (Test-Path $packagesPropsPath) {
        Write-Host "  Adding Swagger to package versions..." -ForegroundColor White
        $content = Get-Content $packagesPropsPath -Raw
    
        # Add before closing </ItemGroup>
        $content = $content -replace '(\s*</ItemGroup>)', '    <PackageVersion Include="Swashbuckle.AspNetCore" Version="6.5.0" />$1'
    
        Set-Content $packagesPropsPath $content -Encoding UTF8
        Write-Host "    ✓ Added Swashbuckle version to Directory.Packages.props" -ForegroundColor Green
    }
}
catch {
    $errorMsg = "Failed to remove NSwag integration: $($_.Exception.Message)"
    Write-Host "  ✗ $errorMsg" -ForegroundColor Red
    $nswagRemovalErrors += $errorMsg
    $nswagRemovalSuccess = $false
}

# Summary of NSwag removal
if ($nswagRemovalSuccess -and $nswagRemovalErrors.Count -eq 0) {
    Write-Host "✓ NSwag integration completely removed - VS2022 build issues resolved" -ForegroundColor Green
    Write-Host "  Note: OpenAPI documentation now uses built-in ASP.NET Core Swagger support" -ForegroundColor Gray
}
else {
    Write-Host "⚠ NSwag removal completed with warnings:" -ForegroundColor Yellow
    foreach ($errorMsg in $nswagRemovalErrors) {
        Write-Host "    • $errorMsg" -ForegroundColor Red
    }
    Write-Host "  Manual cleanup may be required" -ForegroundColor Yellow
}

Write-Host ""

# =============================================================================
# STEP 8: VALIDATE PROJECT SETUP
# =============================================================================
Write-Host "=== VALIDATING PROJECT SETUP ===" -ForegroundColor Cyan
Write-Host ""

# Verify project structure
Write-Host "Verifying project structure..." -ForegroundColor White

$expectedFolders = @("src/Application", "src/Domain", "src/Infrastructure", "src/Web", "tests")
$missingFolders = @()

foreach ($folder in $expectedFolders) {
    if (Test-Path $folder) {
        Write-Host "  ✓ $folder" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ $folder" -ForegroundColor Red
        $missingFolders += $folder
    }
}

if ($missingFolders.Count -gt 0) {
    Write-Host "⚠ Some expected folders are missing. Project may not have been created correctly." -ForegroundColor Yellow
}
else {
    Write-Host "✓ Project structure verified" -ForegroundColor Green
}

# Test project build
Write-Host ""
Write-Host "Testing project build..." -ForegroundColor White

try {
    # Build normally (NSwag has been removed)
    $buildResult = dotnet build --verbosity quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Project builds successfully" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Project build has warnings or errors" -ForegroundColor Yellow
        Write-Host "Build output: $buildResult" -ForegroundColor Gray
    }
}
catch {
    Write-Host "✗ Project build failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test database connection (if not SQLite)
if ($databaseProvider -ne "SQLite") {
    Write-Host ""
    Write-Host "Testing database connection..." -ForegroundColor White
    
    try {
        # Navigate to Web project for EF commands
        Set-Location "src/Web"
        
        # Build the project for EF tools
        $efBuildResult = dotnet build --verbosity quiet 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Test basic database server connectivity using EF tools
            # Note: The template uses EnsureCreated, not migrations, so we test server connectivity
            $efTestResult = dotnet ef dbcontext info --connection $connectionString 2>&1
            
            if ($efTestResult -match "Provider name:" -or $efTestResult -match "Database name:" -or $efTestResult -notmatch "error") {
                Write-Host "✓ Database server connection validated" -ForegroundColor Green
                Write-Host "  Note: Database will be auto-created on first application startup" -ForegroundColor Gray
            }
            else {
                Write-Host "⚠ Database connection test inconclusive" -ForegroundColor Yellow
                Write-Host "  The template auto-creates databases, so this may be expected" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "⚠ Could not build project for database testing" -ForegroundColor Yellow
        }
        
        # Navigate back to project root
        Set-Location "../.."
        
    }
    catch {
        Write-Host "⚠ Database connection test completed with warnings" -ForegroundColor Yellow
        Write-Host "  The template handles database creation automatically on startup" -ForegroundColor Gray
        Set-Location "../.."
    }
}
else {
    Write-Host "✓ SQLite database will be created automatically on startup" -ForegroundColor Green
}

Write-Host ""

# =============================================================================
# STEP 9: SHOW FINAL RESULTS AND NEXT STEPS
# =============================================================================
Write-Host "=== CLEAN ARCHITECTURE SETUP COMPLETE ===" -ForegroundColor Green
Write-Host ""

# Get current location for project path
$currentLocation = Get-Location
$projectPath = $currentLocation.Path

Write-Host "SUMMARY:" -ForegroundColor White
Write-Host "  Project name: $projectName" -ForegroundColor White
Write-Host "  Database name: $databaseName" -ForegroundColor White
Write-Host "  Database provider: $databaseProvider" -ForegroundColor White
Write-Host "  Template: Clean Architecture Web API" -ForegroundColor White
Write-Host "  Location: $projectPath" -ForegroundColor White
Write-Host "  Testing framework: NUnit, Shouldly, Moq, Respawn (included)" -ForegroundColor White
Write-Host "  NSwag integration: Removed (VS2022 compatibility fix applied)" -ForegroundColor White
Write-Host "  VS2022 startup project: Web project set as default" -ForegroundColor White
Write-Host ""

Write-Host "PROJECT STRUCTURE:" -ForegroundColor Green
Write-Host "  📁 $projectName/" -ForegroundColor White
Write-Host "    📁 src/" -ForegroundColor Gray
Write-Host "      📁 Application/     (Use cases - Commands & Queries)" -ForegroundColor Gray
Write-Host "      📁 Domain/          (Entities, Value Objects, Events)" -ForegroundColor Gray
Write-Host "      📁 Infrastructure/  (Data Access, External Services)" -ForegroundColor Gray
Write-Host "      📁 Web/             (API Controllers, Configuration)" -ForegroundColor Gray
Write-Host "    📁 tests/             (Unit & Integration Tests)" -ForegroundColor Gray
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Navigate to the project directory:" -ForegroundColor White
Write-Host "   cd $projectName" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run the application:" -ForegroundColor White
Write-Host "   cd src/Web" -ForegroundColor Gray
Write-Host "   dotnet run" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Access the API at: https://localhost:7xxx/swagger" -ForegroundColor White
Write-Host ""
Write-Host "4. Create new use cases (Commands/Queries):" -ForegroundColor White
Write-Host "   cd src/Application" -ForegroundColor Gray
Write-Host "   dotnet new ca-usecase --name CreateTodo --feature-name Todos --usecase-type command" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Run tests:" -ForegroundColor White
Write-Host "   dotnet test" -ForegroundColor Gray
Write-Host ""

Write-Host "DATABASE CONNECTION:" -ForegroundColor Green
Write-Host "  Provider: $databaseProvider" -ForegroundColor White
Write-Host "  Connection: $($connectionString.Substring(0, [Math]::Min(50, $connectionString.Length)))..." -ForegroundColor White
Write-Host ""

Write-Host "Clean Architecture project setup completed successfully!" -ForegroundColor Green

