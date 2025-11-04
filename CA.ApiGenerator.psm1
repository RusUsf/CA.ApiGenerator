function New-CAApiSolution {
    <#
    .SYNOPSIS
    Generate a production-ready API from your database in one command.

    .DESCRIPTION
    Transforms your existing database into a complete Clean Architecture Web API solution.
    
    Generates automatically:
    - Domain entities from database tables
    - CQRS commands and queries with MediatR for all entities
    - REST API controllers with full CRUD operations
    - FluentValidation rules for input validation
    - Error handling with proper HTTP status codes
    - Swagger/OpenAPI documentation
    - Integration tests ready to run
    
    Supports SQL Server, PostgreSQL, and SQLite databases.
    
    Built on Jason Taylor's Clean Architecture template (ca-sln) with full automation.

    .PARAMETER ConnectionString
    Database connection string. If not provided, you'll be prompted interactively with examples.
    
    SQL Server Examples:
      Windows Auth:     "Server=localhost;Database=Hospital;Integrated Security=true;"
      SQL Auth:         "Server=localhost;Database=Hospital;User Id=sa;Password=Pass123;"
      Named Instance:   "Server=localhost\SQLEXPRESS;Database=Hospital;Integrated Security=true;"
    
    PostgreSQL Examples:
      Default Port:     "Server=localhost;Database=Hospital;User Id=postgres;Password=Pass123;"
      Custom Port:      "Server=localhost;Port=5433;Database=Hospital;User Id=postgres;Password=Pass123;"
    
    SQLite Example:
      File-based:       "Data Source=hospital.db"

    .PARAMETER ProjectName
    Optional. The name for your generated API project.
    
    If not provided, automatically detected from database name.
    Example: Database "Hospital" becomes "Hospital_API"

    .PARAMETER Interactive
    Optional. Force interactive mode even when parameters are provided.
    Useful when you want to review settings before generation.

    .EXAMPLE
    New-CAApiSolution
    
    Runs in interactive mode with prompts and examples.
    Perfect for first-time use or when exploring the module.
    
    Result:
    - Prompts for connection string with examples
    - Auto-detects database provider (SQL Server, PostgreSQL, SQLite)
    - Auto-generates project name from database
    - Creates complete Clean Architecture solution
    - Launches Web project with Swagger UI

    .EXAMPLE
    New-CAApiSolution -ConnectionString "Server=localhost;Database=Hospital;Integrated Security=true;"
    
    Automated generation from SQL Server database.
    Project name auto-detected as "Hospital_API".
    
    Result:
    - Scaffolds entities from all tables in 'dbo' schema
    - Generates CQRS commands/queries for every entity
    - Creates REST controllers for all entities
    - Launches API at http://localhost:5xxx/swagger

    .EXAMPLE
    New-CAApiSolution -ConnectionString "Server=localhost;Database=Hospital;Integrated Security=true;" -ProjectName "HospitalManagementAPI"
    
    Automated generation with custom project name.
    Perfect for CI/CD pipelines and automated workflows.
    
    Result:
    - Solution named "HospitalManagementAPI" instead of default
    - All namespaces use custom name (HospitalManagementAPI.Domain, etc.)
    - Same complete CQRS implementation and REST API

    .EXAMPLE
    New-CAApiSolution -ConnectionString "Server=localhost;Port=5432;Database=ecommerce;User Id=postgres;Password=Pass123;Search Path=sales,public;"
    
    PostgreSQL database with custom schema.
    
    Result:
    - Scaffolds entities from 'sales' and 'public' schemas only
    - Excludes system schemas (pg_catalog, information_schema, sys)
    - Generates complete API for Products, Orders, Customers, etc.
    - Multi-schema support built-in

    .EXAMPLE
    # CI/CD Pipeline Example
    $connectionString = $env:DATABASE_CONNECTION_STRING
    $projectName = $env:PROJECT_NAME
    
    New-CAApiSolution -ConnectionString $connectionString -ProjectName $projectName
    
    Non-interactive automation for build pipelines.
    
    Result:
    - Fully automated API generation from environment variables
    - No prompts or user interaction required
    - Consistent output for automated testing and deployment

    .OUTPUTS
    Complete Clean Architecture solution created in current directory:
    
    YourAPI/
    ├── src/
    │   ├── Domain/              # Entities and domain logic
    │   ├── Application/         # CQRS commands/queries
    │   ├── Infrastructure/      # Database and external services
    │   └── Web/                 # REST API controllers
    └── tests/
        └── Application.FunctionalTests/  # Integration tests
    
    Web project automatically launches with Swagger UI at:
    http://localhost:5xxx/swagger (exact port shown in console)

    .NOTES
    Requirements:
    - PowerShell 5.1 or higher
    - .NET SDK 9.0 or higher (https://dotnet.microsoft.com/download/dotnet/9.0)
    
    Auto-installed dependencies (first run only):
    - Jason Taylor's Clean Architecture template (ca-sln)
    - Entity Framework Core tools (dotnet-ef)
    - Database connectivity modules (dbatools, SimplySql)
    
    Database Requirements:
    ⚠️ Tables MUST use plural names (Doctors, Patients, Orders)
    This ensures proper entity class naming (Doctor, Patient, Order)
    
    First run: ~2 minutes (dependency installation)
    Subsequent runs: ~30 seconds (API generation only)

    .LINK
    GitHub Repository: https://github.com/RusUsf/CA.ApiGenerator
    
    .LINK
    PowerShell Gallery: https://www.powershellgallery.com/packages/CA.ApiGenerator
    
    .LINK
    Jason Taylor's Clean Architecture: https://github.com/jasontaylordev/CleanArchitecture
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            HelpMessage = "Database connection string. Examples provided in interactive mode if omitted."
        )]
        [string]$ConnectionString,

        [Parameter(
            Position = 1,
            HelpMessage = "API project name. Auto-detected from database name if omitted."
        )]
        [string]$ProjectName,

        [Parameter(HelpMessage = "Force interactive mode with prompts.")]
        [switch]$Interactive
    )

    # Set global variables for wrapper scripts to consume
    if ($ConnectionString) {
        $global:CAConnectionString = $ConnectionString
    }

    if ($ProjectName) {
        $global:CAProjectName = $ProjectName
    }

    if ($Interactive) {
        $global:CAInteractive = $true
    }

    try {
        # Get module paths
        $modulePath = $PSScriptRoot
        $wrapperScript = Join-Path $modulePath "bin\Invoke-RunFullPipelineWrapper.ps1"

        # Verify wrapper exists
        if (-not (Test-Path $wrapperScript)) {
            throw "Wrapper script not found: $wrapperScript`n`nModule may not be installed correctly. Try: Install-Module CA.ApiGenerator -Force"
        }

        # Display welcome message for interactive mode
        if (-not $ConnectionString -or $Interactive) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host " CA.ApiGenerator" -ForegroundColor Cyan
            Write-Host " From Database to Production API" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
        }

        # Invoke the wrapper (which invokes the original scripts)
        & $wrapperScript

    } catch {
        Write-Host ""
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "For help, run: Get-Help New-CAApiSolution -Full" -ForegroundColor Yellow
        Write-Host "Report issues: https://github.com/RusUsf/CA.ApiGenerator/issues" -ForegroundColor Yellow
        Write-Host ""
        throw
    } finally {
        # Always clean up global variables
        $global:CAConnectionString = $null
        $global:CAProjectName = $null
        $global:CAInteractive = $null
    }
}

# Export the function
Export-ModuleMember -Function New-CAApiSolution