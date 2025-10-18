@{
    RootModule        = 'CA.ApiGenerator.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'ad98c9c0-7c84-419c-aa8d-d3df5bfca526'
    Author            = 'Ruslan Dubas'
    CompanyName       = 'Personal'
    Description       = 'Generate Clean Architecture API solutions from existing databases with a single PowerShell command'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'New-CAApiSolution'
    CmdletsToExport   = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags                     = 'CleanArchitecture', 'API', 'CodeGeneration', 'CQRS', 'EntityFramework'
            ProjectUri               = 'https://github.com/RusUsf/CA.ApiGenerator'
            ReleaseNotes             = 'Initial preview release. Generates complete Clean Architecture solutions with CQRS boilerplate from existing databases. Supports SQL Server, PostgreSQL, SQLite.'
            Prerelease               = ''
            RequireLicenseAcceptance = $false
        }
    }
} 