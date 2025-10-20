# CA.ApiGenerator PowerShell Module

Generate Clean Architecture API solutions from your existing database with a single command!

> **Built on Jason Taylor's Clean Architecture Template** - This module provides PowerShell automation for [ca-sln](https://github.com/jasontaylordev/CleanArchitecture) to enable database-first solution generation.

![CA API Generator Architecture](./images/CA_API_Generator_PowerPoint.png)

## Installation

```powershell

# Step 1: Install Jason Taylor's CA template (required dependency)
dotnet new install Clean.Architecture.Solution.Template

# Step 2: Install this module from PowerShell Gallery
Install-Module -Name CA.ApiGenerator

# Step 3: Import this module
Import-Module CA.ApiGenerator

# Step 4: Verify installation
Get-Command New-CAApiSolution

```

## Quick Start

### Interactive Mode
```powershell
New-CAApiSolution
```

### Automated Mode
```powershell
New-CAApiSolution `
  -ConnectionString "Server=localhost;Database=mydb;Integrated Security=true;" `
  -ProjectName "MyAPI"
```

## Features

- ✅ Generates complete Clean Architecture solution
- ✅ Supports SQL Server, PostgreSQL
- ✅ CQRS pattern with MediatR
- ✅ FluentValidation for input validation
- ✅ Entity Framework Core integration
- ✅ REST API controllers auto-generated
- ✅ Integrated code generator for future entities
- ✅ Simple PowerShell interface to ca-sln
- ✅ Automated and interactive modes

## Parameters

- **ConnectionString** - Database connection string (optional, prompts if not provided)
- **ProjectName** - API project name (optional, auto-detected from database)

## Examples

See `Get-Help New-CAApiSolution -Examples` for more usage scenarios.

## Requirements

- PowerShell 5.1 or higher
- .NET SDK 9.0 or higher
- dotnet new install Clean.Architecture.Solution.Template

### Database Requirements

⚠️ **IMPORTANT**: All database tables MUST use plural names.

**Why?** The module uses EF Core Power Tools for entity generation, which expects plural table names and automatically singularizes them for entity classes.


## Connection String Examples

### SQL Server

| Scenario | Connection String |
|----------|------------------|
| Default instance (Windows Auth) | `Server=localhost;Database=MyDb;Integrated Security=true;` |
| Default instance (SQL Auth) | `Server=localhost;Database=MyDb;User Id=sa;Password=Pass123;` |
| Named instance (Windows Auth) | `Server=localhost\SQLEXPRESS;Database=MyDb;Integrated Security=true;` |
| Named instance (SQL Auth) | `Server=MYSERVER\INSTANCE01;Database=MyDb;User Id=sa;Password=Pass123;` |

### PostgreSQL

| Scenario | Connection String |
|----------|------------------|
| Default port | `Server=localhost;Database=MyDb;User Id=postgres;Password=Pass123;` |
| Custom port | `Server=localhost;Port=5433;Database=MyDb;User Id=postgres;Password=Pass123;` |
| Remote server | `Server=192.168.1.100;Port=5432;Database=MyDb;User Id=myuser;Password=Pass123;` |

## Credits

- **Clean Architecture Template** by [Jason Taylor](https://github.com/jasontaylordev)
  - Repository: https://github.com/jasontaylordev/CleanArchitecture
  - Template: `Clean.Architecture.Solution.Template`
- **dbatools** - PowerShell module for SQL Server automation
  - Repository: https://github.com/dataplat/dbatools
- **SimplySql** - PowerShell module for cross-database support (PostgreSQL, SQLite)
  - Repository: https://github.com/mithrandyr/SimplySql
- **PowerShell Wrapper** - This module adds database automation on top of these tools

## License

MIT License - see LICENSE file for details

This module wraps Jason Taylor's Clean Architecture template. Please review both licenses.
