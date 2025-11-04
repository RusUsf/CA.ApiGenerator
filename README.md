# CA.ApiGenerator

**Your database already exists. Your API shouldn't take days to build.**

CA.ApiGenerator generates production-ready Clean Architecture APIs from existing databases in minutes - complete with CQRS, validation, error handling, and Swagger docs.

## What You Get

One command transforms this:

```sql
CREATE TABLE Doctors (
    DoctorId INT PRIMARY KEY,
    Name NVARCHAR(100),
    Specialty NVARCHAR(50)
);
```

Into this:

- ✅ `Doctor` entity class with EF Core configuration
- ✅ `GetDoctorsQuery` / `GetDoctorQuery` with MediatR handlers
- ✅ `CreateDoctorCommand` / `UpdateDoctorCommand` / `DeleteDoctorCommand`
- ✅ FluentValidation rules for input validation
- ✅ `DoctorsController` with full REST API endpoints
- ✅ Integration tests ready to run
- ✅ Swagger documentation generated automatically

**All in under 5 minutes.**

## Why This Exists

**The Old Way:**
```
New Feature → Design → SQL Tables → 10+ C# Files → Wire Everything → Test
Timeline: Days or weeks per feature
```

**With CA.ApiGenerator:**
```
SQL Tables → One Command → Production API Running
Timeline: 5 minutes
```

Stop spending 80% of your time writing boilerplate. Focus on business logic instead.

## Quick Start

### One-Command Generation

```powershell
# From SQL Server database to running API
New-CAApiSolution -ConnectionString "Server=localhost;Database=Hospital;Integrated Security=true;"

# Result: 
# ✓ Complete Clean Architecture solution generated
# ✓ Domain entities from all database tables
# ✓ CQRS commands/queries for every entity
# ✓ REST controllers with Swagger docs
# ✓ Web project launches automatically at http://localhost:5xxx/swagger
```

### Interactive Mode (First-Time Use)

```powershell
New-CAApiSolution

# You'll be prompted for:
# 1. Connection string (with examples)
# 2. Project name (auto-detected from database)
# Then sit back and watch your API generate!
```

## Installation

```powershell
# Step 1: Install .NET 9 SDK (required)
# Download from: https://dotnet.microsoft.com/download/dotnet/9.0

# Step 2: Install this module from PowerShell Gallery
Install-Module -Name CA.ApiGenerator -Scope CurrentUser

# Step 3: Generate your first API!
New-CAApiSolution
```

**First run?** The module auto-installs these dependencies for you:
- Jason Taylor's Clean Architecture template (`ca-sln`)
- Entity Framework Core tools (`dotnet-ef`)
- Database connectivity modules (`dbatools`, `SimplySql`)

First run takes ~2 minutes (dependency installation). Every run after is instant.

## Features

### What Gets Generated

**Domain Layer:**
- Entity classes from database tables
- Base entities with audit capabilities
- Domain events infrastructure

**Application Layer:**
- CQRS queries: `GetAll`, `GetById` for every entity
- CQRS commands: `Create`, `Update`, `Delete` for every entity
- DTOs with AutoMapper configuration
- FluentValidation rules for all commands

**Infrastructure Layer:**
- DbContext with all entities configured
- Entity configurations for EF Core
- Database connection setup
- Audit interceptor for tracking changes

**Web Layer:**
- REST API controllers for all entities
- Swagger/OpenAPI documentation
- Centralized error handling with ProblemDetails
- CORS and health check endpoints

**Tests:**
- Integration test project with test fixtures
- Sample tests for each entity's CRUD operations

### Built-In Patterns

- ✅ **Clean Architecture** - Proper layer separation (Domain, Application, Infrastructure, Web)
- ✅ **CQRS** - Command/query separation with MediatR
- ✅ **Repository Pattern** - DbContext abstraction
- ✅ **Unit of Work** - Transaction management via DbContext
- ✅ **Validation** - FluentValidation for input validation
- ✅ **Error Handling** - Centralized exception handling with proper HTTP status codes
- ✅ **Dependency Injection** - All dependencies properly registered
- ✅ **Soft Delete** - Automatic detection and implementation if `RecDelete` column exists
- ✅ **Audit Trail** - Automatic tracking if audit columns exist (`Created`, `CreatedBy`, `LastModified`, `LastModifiedBy`)

## Database Support

| Database | Connection String Example |
|----------|--------------------------|
| **SQL Server** (Windows Auth) | `Server=localhost;Database=MyDb;Integrated Security=true;` |
| **SQL Server** (SQL Auth) | `Server=localhost;Database=MyDb;User Id=sa;Password=Pass123;` |
| **SQL Server** (Named Instance) | `Server=localhost\SQLEXPRESS;Database=MyDb;Integrated Security=true;` |
| **PostgreSQL** (Default Port) | `Server=localhost;Database=MyDb;User Id=postgres;Password=Pass123;` |
| **PostgreSQL** (Custom Port) | `Server=localhost;Port=5433;Database=MyDb;User Id=postgres;Password=Pass123;` |
| **SQLite** | `Data Source=app.db` |

### Important: Table Naming Convention

⚠️ **Your database tables MUST use plural names** (e.g., `Doctors`, `Patients`, `Appointments`)

**Why?** Entity Framework Core expects plural table names and singularizes them for entity classes:
- Table `Doctors` → Entity class `Doctor` → Controller `DoctorsController`

This ensures accurate code generation and proper pluralization throughout your API.

## Examples

### Example 1: Hospital Management API

```powershell
# Your existing database has: Doctors, Patients, Appointments, MedicalRecords
New-CAApiSolution -ConnectionString "Server=localhost;Database=Hospital;Integrated Security=true;"

# Generated API includes:
# GET    /api/Doctors          - List all doctors
# GET    /api/Doctors/{id}     - Get doctor by ID
# POST   /api/Doctors          - Create new doctor
# PUT    /api/Doctors/{id}     - Update doctor
# DELETE /api/Doctors/{id}     - Delete doctor
# (Same endpoints for Patients, Appointments, MedicalRecords)
```

### Example 2: E-Commerce API

```powershell
# Database tables: Products, Categories, Orders, OrderItems, Customers
New-CAApiSolution `
  -ConnectionString "Server=myserver.database.windows.net;Database=ECommerce;User Id=admin;Password=SecurePass123;" `
  -ProjectName "ECommerceAPI"

# Result: Complete e-commerce API with all CRUD operations
# Ready to integrate with your frontend or mobile app
```

### Example 3: PostgreSQL Multi-Schema

```powershell
# PostgreSQL database with custom schema
New-CAApiSolution -ConnectionString "Server=localhost;Port=5432;Database=MyApp;User Id=postgres;Password=Pass123;Search Path=sales,public;"

# Scaffolds entities from 'sales' and 'public' schemas
# Excludes system schemas automatically
```

## What Makes This Different?

### vs. Manual Clean Architecture Setup
- **Manual:** Days of boilerplate, potential inconsistencies
- **CA.ApiGenerator:** 5 minutes, consistent patterns enforced

### vs. EF Core Scaffolding Alone
- **EF Scaffolding:** Just entities and DbContext
- **CA.ApiGenerator:** Complete solution with CQRS, controllers, tests, validation

### vs. Jason Taylor's CA Template
- **CA Template:** Great starting point, requires manual entity creation
- **CA.ApiGenerator:** Automated database-first generation built on the template

### vs. Other Code Generators
- **Other Generators:** Often produce low-quality or outdated patterns
- **CA.ApiGenerator:** Production-ready code following modern best practices

## Generated Solution Structure

```
MyAPI/
├── src/
│   ├── Domain/                    # Business entities and rules
│   │   ├── Entities/              # Your database tables as entity classes
│   │   └── Common/                # Base entities with audit support
│   ├── Application/               # Business logic and CQRS
│   │   ├── Doctors/               # Per-entity folders
│   │   │   ├── Commands/          # Create, Update, Delete commands
│   │   │   ├── Queries/           # GetAll, GetById queries
│   │   │   └── Models/            # DTOs with mapping
│   │   └── Common/                # Shared interfaces and behaviors
│   ├── Infrastructure/            # Database and external services
│   │   └── Data/                  # DbContext and configurations
│   └── Web/                       # API presentation layer
│       ├── Controllers/           # REST API endpoints
│       └── appsettings.json       # Configuration
└── tests/
    └── Application.FunctionalTests/  # Integration tests
```

## Requirements

### Manual Installation Required

1. **.NET SDK 9.0 or higher**  
   Download: https://dotnet.microsoft.com/download/dotnet/9.0

2. **PowerShell 5.1 or higher**  
   Pre-installed on Windows. For macOS/Linux: https://github.com/PowerShell/PowerShell

### Auto-Installed by Module

✅ Jason Taylor's Clean Architecture template  
✅ Entity Framework Core tools (`dotnet-ef`)  
✅ Database connectivity modules (`dbatools`, `SimplySql`)

## Troubleshooting

### "Module failed to install dependencies"

Dependencies install automatically, but if it fails:

```powershell
# Install PowerShell modules manually
Install-Module dbatools -Force -Scope CurrentUser
Install-Module SimplySql -Force -Scope CurrentUser

# Install .NET template manually
dotnet new install Clean.Architecture.Solution.Template

# Install EF tools manually
dotnet tool install --global dotnet-ef

# Try again
New-CAApiSolution
```

### ".NET SDK version too old"

**Error:** "Requires .NET 9.0 or higher"

**Solution:** Download and install .NET 9 SDK from:  
https://dotnet.microsoft.com/download/dotnet/9.0

After installation, **restart PowerShell** and try again.

### "Table names must be plural"

**Error:** "Entity generation failed due to naming conventions"

**Solution:** Rename your tables to use plural names:

```sql
-- SQL Server
EXEC sp_rename 'Doctor', 'Doctors';

-- PostgreSQL
ALTER TABLE "Doctor" RENAME TO "Doctors";
```

Then regenerate your API.

## Advanced Usage

### Custom Project Name

```powershell
# Auto-detected project name from database
New-CAApiSolution -ConnectionString "Server=localhost;Database=Sales;..."
# Result: Sales_API

# Custom project name
New-CAApiSolution -ConnectionString "..." -ProjectName "MyCustomAPI"
# Result: MyCustomAPI
```

### Automation & CI/CD

```powershell
# Non-interactive mode for build pipelines
New-CAApiSolution `
  -ConnectionString $env:DATABASE_CONNECTION_STRING `
  -ProjectName $env:PROJECT_NAME

# Result: Fully automated API generation in CI/CD
```

## Credits

**Built on top of:**
- **Clean Architecture Template** by [Jason Taylor](https://github.com/jasontaylordev/CleanArchitecture)
- **dbatools** - SQL Server automation by [dataplat](https://dbatools.io)
- **SimplySql** - Cross-database support by [mithrandyr](https://github.com/mithrandyr/SimplySql)

This module provides PowerShell automation and database-first generation on top of these excellent tools.

## License

MIT License - See [LICENSE](LICENSE) file for details

This module wraps Jason Taylor's Clean Architecture template. Please review both licenses.

## Support

- **Issues & Bug Reports:** https://github.com/RusUsf/CA.ApiGenerator/issues
- **Documentation:** https://github.com/RusUsf/CA.ApiGenerator
- **PowerShell Gallery:** https://www.powershellgallery.com/packages/CA.ApiGenerator

---

**Stop writing boilerplate. Start shipping features.** 🚀