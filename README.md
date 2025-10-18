# CA.ApiGenerator PowerShell Module

Generate Clean Architecture API solutions from your existing database with a single command!

## Installation

```powershell
# Import the module
Import-Module .\CA.ApiGenerator\CA.ApiGenerator.psd1

# Verify installation
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
- ✅ Supports SQL Server, PostgreSQL, SQLite
- ✅ CQRS pattern with MediatR
- ✅ FluentValidation for input validation
- ✅ Entity Framework Core integration
- ✅ REST API controllers auto-generated
- ✅ Integrated code generator for future entities

## Parameters

- **ConnectionString** - Database connection string (optional, prompts if not provided)
- **ProjectName** - API project name (optional, auto-detected from database)
- **Interactive** - Force interactive prompts even when parameters provided

## Examples

See `Get-Help New-CAApiSolution -Examples` for more usage scenarios.

## Requirements

- PowerShell 5.1 or higher
- .NET SDK 6.0 or higher
- Access to target database

## License

MIT License - see LICENSE file for details
