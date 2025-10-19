function New-CAApiSolution {
    <#
    .SYNOPSIS
    Creates a Clean Architecture API solution from an existing database.

    .DESCRIPTION
    Automates the complete process of generating a Clean Architecture Web API
    from your existing database schema. Generates entities, CQRS commands/queries,
    validators, and REST controllers automatically.

    Supports SQL Server, PostgreSQL, and SQLite databases.

    .PARAMETER ConnectionString
    The database connection string. If not provided, you'll be prompted interactively.

    Examples:
    - SQL Server: "Server=localhost;Database=mydb;Integrated Security=true;"
    - SQL Server: "Server=TargetServer\InstanceName;Database=mydb;Integrated Security=true;"
    - PostgreSQL: "Server=localhost;Port=5432;Database=mydb;User Id=postgres;Password=pwd;"
    - SQLite: "Data Source=app.db"

    .PARAMETER ProjectName
    Optional. The name for your generated API project.
    If not provided, auto-detected from database name.

    .PARAMETER Interactive
    Optional. Force interactive mode even when parameters are provided.

    .EXAMPLE
    New-CAApiSolution

    Runs in interactive mode, prompting for all inputs.

    .EXAMPLE
    New-CAApiSolution -ConnectionString "Server=localhost;Database=mydb;Integrated Security=true;"

    Creates solution with specified connection string, auto-detects project name.

    .EXAMPLE
    New-CAApiSolution -ConnectionString "Server=localhost;Database=mydb;Integrated Security=true;" -ProjectName "MyAPI"

    Creates solution with explicit connection string and project name. Perfect for automation!

    .OUTPUTS
    Complete Clean Architecture solution in current directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConnectionString,

        [Parameter()]
        [string]$ProjectName,

        [Parameter()]
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
            throw "Wrapper script not found: $wrapperScript"
        }

        # Invoke the wrapper (which invokes the original scripts)
        & $wrapperScript

    } finally {
        # Always clean up global variables
        $global:CAConnectionString = $null
        $global:CAProjectName = $null
        $global:CAInteractive = $null
    }
}

# Export the function
Export-ModuleMember -Function New-CAApiSolution
