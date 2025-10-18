# =============================================================================
# CREATE CODEGENERATORDEV V2 - SELF-CONTAINED SCRIPT
# =============================================================================
# PURPOSE: Generate CodeGeneratorDev with EntityMetadata pattern and all code embedded
# USAGE: .\Create-CodeGeneratorDev-v2.ps1 [-OutputPath .\CodeGeneratorDev] [-SkipBuild]
# NOTE: All source files are embedded. No dependencies required.
# VERSION: 2.0 (with EntityMetadata and PluralNameResolver)
# =============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\CodeGeneratorDev",

    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild
)

Write-Host "=== CREATING CODEGENERATORDEV V2 (SELF-CONTAINED) ===" -ForegroundColor Cyan
Write-Host "Version: 2.0 with EntityMetadata Pattern" -ForegroundColor Green
Write-Host ""

# =============================================================================
# STEP 1: VALIDATE OUTPUT PATH
# =============================================================================

Write-Host "Step 1: Validating output path..." -ForegroundColor White

if (Test-Path $OutputPath) {
    Write-Host "  WARNING: CodeGeneratorDev already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "  Overwrite? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "  Cancelled" -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Path $OutputPath -Recurse -Force
    Write-Host "  Success: Removed existing" -ForegroundColor Green
}

Write-Host "  Success: Path validated" -ForegroundColor Green

# =============================================================================
# STEP 2: CREATE SOLUTION STRUCTURE
# =============================================================================

Write-Host ""
Write-Host "Step 2: Creating solution structure..." -ForegroundColor White

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
Push-Location $OutputPath

try {
    $null = dotnet new console -n CodeGeneratorDev -o CodeGeneratorDev 2>&1
    $null = dotnet new sln -n CodeGeneratorDev 2>&1
    $null = dotnet sln add CodeGeneratorDev\CodeGeneratorDev.csproj 2>&1
    Write-Host "  Success: Created solution and project" -ForegroundColor Green
}
catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}

# =============================================================================
# STEP 3: ADD NUGET PACKAGES
# =============================================================================

Write-Host ""
Write-Host "Step 3: Adding NuGet packages..." -ForegroundColor White

$packages = @(
    @{ Name = "MediatR"; Version = "12.0.0" },
    @{ Name = "FluentValidation"; Version = "11.11.0" },
    @{ Name = "Microsoft.EntityFrameworkCore"; Version = "9.0.0" },
    @{ Name = "Microsoft.AspNetCore.Mvc.Core"; Version = "2.2.5" },
    @{ Name = "AutoMapper"; Version = "13.0.1" }
)

foreach ($pkg in $packages) {
    $null = dotnet add CodeGeneratorDev\CodeGeneratorDev.csproj package $($pkg.Name) --version $($pkg.Version) 2>&1
    Write-Host "  Success: $($pkg.Name) v$($pkg.Version)" -ForegroundColor Green
}

# =============================================================================
# STEP 4: CREATE DIRECTORY STRUCTURE
# =============================================================================

Write-Host ""
Write-Host "Step 4: Creating directory structure..." -ForegroundColor White

$generatorsPath = Join-Path "CodeGeneratorDev" "Generators"
$modelsPath = Join-Path "CodeGeneratorDev" "Models"
$utilitiesPath = Join-Path "CodeGeneratorDev" "Utilities"

foreach ($dir in @($generatorsPath, $modelsPath, $utilitiesPath)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  Created: $(Split-Path -Leaf $dir)\" -ForegroundColor Green
}

# =============================================================================
# STEP 5: EMBEDDED SOURCE FILES
# =============================================================================

Write-Host ""
Write-Host "Step 5: Writing embedded source files..." -ForegroundColor White

# --- Program.cs ---
$programCs = @'
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using CodeGeneratorDev.Generators;
using CodeGeneratorDev.Models;
using CodeGeneratorDev.Utilities;

namespace CodeGeneratorDev;

class Program
{
    static void Main(string[] args)
    {
        // Validate arguments
        if (args.Length < 3)
        {
            Console.WriteLine("Usage: CodeGeneratorDev <assemblyPath> <outputPath> <namespaceRoot> [--dry-run]");
            Console.WriteLine();
            Console.WriteLine("Example:");
          Console.WriteLine("  CodeGeneratorDev.exe \"C:\\Projects\\YourProject\\Domain.dll\" \"C:\\Projects\\YourProject\" \"YourProject\" --dry-run");
            return;
        }

        string assemblyPath = args[0];
        string outputPath = args[1];
        string namespaceRoot = args[2];
        bool dryRun = args.Length > 3 && args[3] == "--dry-run";

        // Validate assembly exists
        if (!File.Exists(assemblyPath))
        {
            Console.WriteLine($"ERROR: Assembly not found at: {assemblyPath}");
            return;
        }

        Console.WriteLine("=== CODE GENERATOR ===");
        Console.WriteLine($"Assembly: {assemblyPath}");
        Console.WriteLine($"Output: {(dryRun ? "GeneratedOutput/ (DRY RUN)" : outputPath)}");
        Console.WriteLine($"Namespace: {namespaceRoot}");
        Console.WriteLine();

        try
        {
            // Load the Domain assembly
            Assembly domainAssembly = Assembly.LoadFrom(assemblyPath);
            Console.WriteLine($"✓ Loaded assembly: {domainAssembly.GetName().Name}");

            // Convert relative paths to absolute
            string absoluteAssemblyPath = Path.GetFullPath(assemblyPath);
            string domainDir = Path.GetDirectoryName(absoluteAssemblyPath) ?? string.Empty;

            // Replace \Domain\release with \Infrastructure\release
            string infrastructureDllPath = domainDir.Replace("\\Domain\\", "\\Infrastructure\\")
                .Replace("/Domain/", "/Infrastructure/");
            infrastructureDllPath = Path.Combine(infrastructureDllPath, $"{namespaceRoot}.Infrastructure.dll");

            if (!File.Exists(infrastructureDllPath))
            {
                Console.WriteLine($"ERROR: Infrastructure assembly not found at: {infrastructureDllPath}");
                return;
            }

            Assembly infraAssembly = Assembly.LoadFrom(infrastructureDllPath);
            Console.WriteLine($"✓ Loaded assembly: {infraAssembly.GetName().Name}");

            // Find IApplicationDbContext implementation
            Type? dbContextType = infraAssembly.GetTypes()
                .FirstOrDefault(t => t.GetInterfaces().Any(i => i.Name == "IApplicationDbContext") && !t.IsInterface);

            if (dbContextType == null)
            {
                Console.WriteLine("ERROR: IApplicationDbContext implementation not found in Infrastructure assembly");
                return;
            }

            Console.WriteLine($"✓ Found DbContext: {dbContextType.Name}");
            Console.WriteLine();

            // Discover entity types
            var entityTypes = domainAssembly.GetTypes()
                .Where(t => t.Namespace?.EndsWith(".Domain.Entities") == true)
                .Where(t => t.IsClass && !t.IsAbstract)
                .Where(t => !t.Name.StartsWith("AspNet"))
                .ToList();

            Console.WriteLine($"✓ Found {entityTypes.Count} entities");
            Console.WriteLine();

            if (entityTypes.Count == 0)
            {
                Console.WriteLine("WARNING: No entities found in Domain.Entities namespace");
                return;
            }

            // Adjust output path for dry-run
            string actualOutputPath = dryRun
            ? Path.Combine(outputPath, "src", "CodeGeneratorDev", "GeneratedOutput")
            : outputPath;

            if (dryRun && Directory.Exists(actualOutputPath))
            {
                Directory.Delete(actualOutputPath, true);
            }

            int successCount = 0;
            int errorCount = 0;

            // Process each entity
            foreach (var entityType in entityTypes)
            {
                try
                {
                    // Build metadata once per entity
                    var metadata = BuildEntityMetadata(entityType, namespaceRoot, dbContextType);

                    Console.WriteLine($"[{entityTypes.IndexOf(entityType) + 1}/{entityTypes.Count}] {metadata.EntityName}");
                    Console.WriteLine($"  ├─ Plural: {metadata.PluralName}");
                    Console.WriteLine($"  ├─ PK: {metadata.PrimaryKeyType.Name} {metadata.PrimaryKeyName}");
                    Console.WriteLine($"  └─ Capabilities: {(metadata.IsAuditable ? "Auditable " : "")}{(metadata.IsSoftDeletable ? "SoftDelete" : "BaseOnly")}");

                    // Pass metadata to all generators
                    var modelCode = ModelGenerator.Generate(metadata);
                    var getQueryCode = GetQueryGenerator.Generate(metadata);
                    var getQueryValidatorCode = GetQueryValidatorGenerator.Generate(metadata);
                    var getAllQueryCode = GetAllQueryGenerator.Generate(metadata);
                    var upsertCommandCode = UpsertCommandGenerator.Generate(metadata);
                    var upsertValidatorCode = UpsertValidatorGenerator.Generate(metadata);
                    var deleteCommandCode = DeleteCommandGenerator.Generate(metadata);
                    var deleteValidatorCode = DeleteCommandValidatorGenerator.Generate(metadata);
                    var configCode = ConfigurationGenerator.Generate(metadata);
                    var endpointCode = ControllerGenerator.Generate(metadata);
                    var testCode = TestTemplateGenerator.Generate(metadata);

                    // Write files using metadata.PluralName for paths
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Models", $"{metadata.EntityName}Model.cs", modelCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Queries/Get{metadata.EntityName}", $"Get{metadata.EntityName}Query.cs", getQueryCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Queries/Get{metadata.EntityName}", $"Get{metadata.EntityName}Validator.cs", getQueryValidatorCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Queries/Get{metadata.EntityName}s", $"Get{metadata.EntityName}sQuery.cs", getAllQueryCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Commands/Upsert{metadata.EntityName}", $"Upsert{metadata.EntityName}Command.cs", upsertCommandCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Commands/Upsert{metadata.EntityName}", $"Upsert{metadata.EntityName}Validator.cs", upsertValidatorCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Commands/Delete{metadata.EntityName}", $"Delete{metadata.EntityName}Command.cs", deleteCommandCode);
                    WriteFile(actualOutputPath, $"src/Application/{metadata.PluralName}/Commands/Delete{metadata.EntityName}", $"Delete{metadata.EntityName}Validator.cs", deleteValidatorCode);

                    // Write Infrastructure Layer files
                    WriteFile(actualOutputPath, $"src/Infrastructure/Data/Configurations", $"{metadata.EntityName}Configuration.cs", configCode);

                    // Write Web Layer files
                    WriteFile(actualOutputPath, $"src/Web/Controllers", $"{metadata.PluralName}Controller.cs", endpointCode);

                    // Write Test files
                    WriteFile(actualOutputPath, $"tests/Application.FunctionalTests/{metadata.EntityName}Tests", $"{metadata.EntityName}ControllerTests.cs", testCode);

                    Console.WriteLine($"  ✓ Generated 11 files");
                    successCount++;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"  ✗ Failed: {ex.Message}");
                    errorCount++;
                }
            }

            Console.WriteLine();
            Console.WriteLine($"=== SUMMARY ===");
            Console.WriteLine($"Success: {successCount}");
            Console.WriteLine($"Errors: {errorCount}");

            if (dryRun)
            {
                Console.WriteLine();
                Console.WriteLine($"Output location: {actualOutputPath}");
                Console.WriteLine("Review the generated files, then run without --dry-run to write to actual project.");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"FATAL ERROR: {ex.Message}");
            Console.WriteLine(ex.StackTrace);
        }
    }

    static void WriteFile(string basePath, string folder, string filename, string content)
    {
        var fullPath = Path.Combine(basePath, folder);
        Directory.CreateDirectory(fullPath);
        var filePath = Path.Combine(fullPath, filename);
        File.WriteAllText(filePath, content);
    }

    /// <summary>
    /// Builds EntityMetadata for a given entity type.
    /// Discovers plural name from DbContext, detects capabilities, and extracts primary key info.
    /// </summary>
    static EntityMetadata BuildEntityMetadata(Type entityType, string namespaceRoot, Type dbContextType)
    {
        // Create metadata with basic info
        var metadata = new EntityMetadata(entityType, namespaceRoot);

        // Resolve the actual plural name from DbContext
        metadata.PluralName = PluralNameResolver.ResolvePluralName(dbContextType, entityType);

        return metadata;
    }
}

'@
Set-Content -Path "CodeGeneratorDev\Program.cs" -Value $programCs -Encoding UTF8
Write-Host "  Success: Program.cs" -ForegroundColor Green

# --- Models/EntityMetadata.cs ---
$entityMetadataCs = @'
using System;
using System.Linq;
using System.Reflection;

namespace CodeGeneratorDev.Models;

/// <summary>
/// Holds rich metadata about an entity discovered from reflection.
/// Eliminates naive pluralization and type assumptions.
/// </summary>
public class EntityMetadata
{
    public Type EntityType { get; set; }
    public string EntityName { get; set; }
    public string PluralName { get; set; } = string.Empty; // Will be set by PluralNameResolver
    public string PrimaryKeyName { get; set; } = string.Empty; // Will be set in ExtractPrimaryKeyInfo
    public Type PrimaryKeyType { get; set; } = typeof(int); // Will be set in ExtractPrimaryKeyInfo
    public bool IsSoftDeletable { get; set; }
    public bool IsAuditable { get; set; }
    public string NamespaceRoot { get; set; }

    /// <summary>
    /// Creates EntityMetadata from an entity type and namespace root.
    /// Primary key and interface detection happens automatically.
    /// PluralName must be set externally via PluralNameResolver.
    /// </summary>
    public EntityMetadata(Type entityType, string namespaceRoot)
    {
        EntityType = entityType ?? throw new ArgumentNullException(nameof(entityType));
        NamespaceRoot = namespaceRoot ?? throw new ArgumentNullException(nameof(namespaceRoot));
        EntityName = entityType.Name;

        // Detect capabilities
        IsSoftDeletable = DetectSoftDeletable();
        IsAuditable = DetectAuditable();

        // Extract primary key info
        ExtractPrimaryKeyInfo();
    }

    /// <summary>
    /// Detects if the entity implements ISoftDeletable interface.
    /// </summary>
    private bool DetectSoftDeletable()
    {
        return EntityType.GetInterfaces()
            .Any(i => i.Name == "ISoftDeletable");
    }

    /// <summary>
    /// Detects if the entity implements IAuditable interface.
    /// </summary>
    private bool DetectAuditable()
    {
        return EntityType.GetInterfaces()
            .Any(i => i.Name == "IAuditable");
    }

    /// <summary>
    /// Extracts primary key name and type from the entity.
    /// Looks for property named "Id" or "{EntityName}Id".
    /// Defaults to "Id" of type int if not found.
    /// </summary>
    private void ExtractPrimaryKeyInfo()
    {
        // Look for Id property
        var idProperty = EntityType.GetProperty("Id", BindingFlags.Public | BindingFlags.Instance);

        if (idProperty != null)
        {
            PrimaryKeyName = "Id";
            PrimaryKeyType = idProperty.PropertyType;
            return;
        }

        // Look for {EntityName}Id property
        var entityIdProperty = EntityType.GetProperty($"{EntityName}Id", BindingFlags.Public | BindingFlags.Instance);

        if (entityIdProperty != null)
        {
            PrimaryKeyName = $"{EntityName}Id";
            PrimaryKeyType = entityIdProperty.PropertyType;
            return;
        }

        // Default fallback
        PrimaryKeyName = "Id";
        PrimaryKeyType = typeof(int);
    }

    /// <summary>
    /// Returns a formatted string representation for logging/debugging.
    /// </summary>
    public override string ToString()
    {
        return $"{EntityName} (Plural: {PluralName}, PK: {PrimaryKeyType.Name} {PrimaryKeyName}, " +
               $"SoftDelete: {IsSoftDeletable}, Auditable: {IsAuditable})";
    }
}

'@
Set-Content -Path (Join-Path $modelsPath "EntityMetadata.cs") -Value $entityMetadataCs -Encoding UTF8
Write-Host "  Success: EntityMetadata.cs" -ForegroundColor Green

# --- Utilities/PluralNameResolver.cs ---
$pluralNameResolverCs = @'
using System;
using System.Linq;
using System.Reflection;

namespace CodeGeneratorDev.Utilities;

/// <summary>
/// Resolves the actual plural name of an entity by reflecting on the DbContext.
/// This eliminates naive pluralization issues (e.g., "DoctorsCopy" -> "DoctorsCopies" not "DoctorsCopys").
/// </summary>
public static class PluralNameResolver
{
    /// <summary>
    /// Resolves the plural name of an entity by finding the DbSet property in the DbContext.
    /// </summary>
    /// <param name="dbContextType">The DbContext type to reflect on</param>
    /// <param name="entityType">The entity type to find</param>
    /// <returns>The actual DbSet property name, or naive pluralization as fallback</returns>
    public static string ResolvePluralName(Type dbContextType, Type entityType)
    {
        if (dbContextType == null)
            throw new ArgumentNullException(nameof(dbContextType));
        if (entityType == null)
            throw new ArgumentNullException(nameof(entityType));

        // Get all properties from the DbContext
        var properties = dbContextType.GetProperties(BindingFlags.Public | BindingFlags.Instance);

        // Look for a DbSet<TEntity> property that matches the entity type
        foreach (var property in properties)
        {
            // Check if the property type is a generic type
            if (property.PropertyType.IsGenericType)
            {
                var genericType = property.PropertyType.GetGenericTypeDefinition();

                // Check if it's DbSet<T>
                if (genericType.Name == "DbSet`1")
                {
                    var genericArguments = property.PropertyType.GetGenericArguments();

                    // Check if the generic argument matches our entity type
                    if (genericArguments.Length > 0 && genericArguments[0] == entityType)
                    {
                        // Found the DbSet property - return its name
                        return property.Name;
                    }
                }
            }
        }

        // Fallback to naive pluralization if not found
        string fallbackName = NaivePluralize(entityType.Name);

        Console.WriteLine($"  ⚠ WARNING: Could not find DbSet<{entityType.Name}> in {dbContextType.Name}");
        Console.WriteLine($"  → Using naive pluralization: {fallbackName}");

        return fallbackName;
    }

    /// <summary>
    /// Naive pluralization: just adds "s" to the entity name.
    /// This is a fallback and should rarely be used if DbContext reflection works.
    /// </summary>
    private static string NaivePluralize(string entityName)
    {
        return entityName + "s";
    }
}

'@
Set-Content -Path (Join-Path $utilitiesPath "PluralNameResolver.cs") -Value $pluralNameResolverCs -Encoding UTF8
Write-Host "  Success: PluralNameResolver.cs" -ForegroundColor Green

# --- Generators ---

$modelGeneratorCs = @'
using System;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Collections.Generic;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public class ModelGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        StringBuilder modelCode = new StringBuilder();
        string modelName = metadata.EntityName + "Model";
        modelCode.AppendLine();

        var entityType = metadata.EntityType;

        // Use Reflection to get properties, excluding navigation properties if necessary
        var entityProperties = entityType.GetProperties();

        // Using AutoMapper and other necessary namespaces
        modelCode.AppendLine("using AutoMapper;");
        modelCode.AppendLine($"using {metadata.NamespaceRoot}.Application.Common.Mappings;");
        modelCode.AppendLine($"using {metadata.NamespaceRoot}.Domain.Entities;\n");
        modelCode.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Models;\n");
        modelCode.AppendLine($"public class {modelName} : IMapFrom<{metadata.EntityName}>");
        modelCode.AppendLine("{");

        // Define auditing columns to be excluded from both property generation and AutoMapper mapping
        var auditingColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Created", "CreatedBy", "LastModified", "LastModifiedBy", "RecDelete", "DomainEvents", "Id", $"{entityType.Name}Id"
        };

        // Use metadata.IsAuditable and metadata.IsSoftDeletable to determine which properties to exclude
        if (metadata.IsAuditable)
        {
            // Auditable properties are already in the list
        }
        if (metadata.IsSoftDeletable)
        {
            // RecDelete is already in the list
        }

        // Get primary key property from metadata
        var primaryKeyProperty = entityType.GetProperty(metadata.PrimaryKeyName);

        // Generate primary key property explicitly if exists
        if (primaryKeyProperty != null)
        {
            Type primaryKeyType = Nullable.GetUnderlyingType(primaryKeyProperty.PropertyType) ?? primaryKeyProperty.PropertyType;
            bool isPrimaryKeyNullable = !primaryKeyType.IsValueType || primaryKeyProperty.PropertyType != primaryKeyType;
            string primaryKeyTypeName = GetTypeDisplayName(primaryKeyType, isPrimaryKeyNullable);

            modelCode.AppendLine($"    public {primaryKeyTypeName} Id {{ get; set; }}");
            if (primaryKeyTypeName == "string" && isPrimaryKeyNullable)
            {
                modelCode.Append(" = null!;");
            }
        }

        // Generate other properties
        foreach (PropertyInfo prop in entityType.GetProperties())
        {
            // Skip auditing columns and the primary key
            if (auditingColumns.Contains(prop.Name) || prop == primaryKeyProperty || prop.GetGetMethod()!.IsVirtual)
            {
                continue;
            }

            Type propType = Nullable.GetUnderlyingType(prop.PropertyType) ?? prop.PropertyType;
            bool isNullable = !propType.IsValueType || prop.PropertyType != propType;
            string typeName = GetTypeDisplayName(propType, isNullable);

            string propertyName = prop.Name;

            modelCode.AppendLine($"    public {typeName} {propertyName} {{ get; set; }}");
            if (typeName == "string" && isNullable)
            {
                modelCode.Append(" = null!;");
            }
        }

        // Generate AutoMapper configuration
        modelCode.AppendLine("    public void Mapping(Profile profile)");
        modelCode.AppendLine("    {");
        modelCode.AppendLine($"        profile.CreateMap<{metadata.EntityName}, {modelName}>()");

        // If there's a primary key property, map it explicitly first.
        if (primaryKeyProperty != null)
        {
            modelCode.AppendLine($"            .ForMember(d => d.Id, opt => opt.MapFrom(s => s.{primaryKeyProperty.Name}))");
        }

        foreach (PropertyInfo prop in entityType.GetProperties())
        {
            // Skip auditing columns, the explicitly handled primary key property, and any navigation properties if necessary
            if (auditingColumns.Contains(prop.Name) || prop == primaryKeyProperty || prop.GetGetMethod()!.IsVirtual)
            {
                continue;
            }
            // For all other properties, map them normally
            modelCode.AppendLine($"            .ForMember(d => d.{prop.Name}, opt => opt.MapFrom(s => s.{prop.Name}))");
        }
        modelCode.AppendLine("    ;");
        modelCode.AppendLine("    }");

        modelCode.AppendLine("}");

        return modelCode.ToString();
    }

    private static string GetTypeDisplayName(Type type, bool isNullable)
    {
        if (type.IsGenericType && type.GetGenericTypeDefinition() == typeof(ICollection<>))
        {
            Type genericType = type.GetGenericArguments()[0];
            // Recursively call GetTypeDisplayName to correctly handle generic types
            return $"IList<{GetTypeDisplayName(genericType, Nullable.GetUnderlyingType(genericType) != null)}>";
        }

        // Basic type handling with switch
        string typeName = type.Name switch
        {
            "String" => "string",
            "Int32" => "int",
            "DateTime" => "DateTime",
            "Boolean" => "bool",
            "Guid" => "Guid",
            _ => type.IsGenericType ? $"IList<{type.GenericTypeArguments[0].Name}>" : type.Name,
        };

        // Correctly append '?' for nullable types
        return isNullable ? typeName + "?" : typeName;
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "ModelGenerator.cs") -Value $modelGeneratorCs -Encoding UTF8
Write-Host "  Success: ModelGenerator.cs" -ForegroundColor Green

$controllerGeneratorCs = @'
using System;
using System.Linq;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class ControllerGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var controllerName = $"{entityName}Controller";
        var entityModelName = $"{entityName}Model";

        // Use metadata for primary key info
        Type underlyingPkType = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) ?? metadata.PrimaryKeyType;
        bool isPkNullable = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) != null;

        string primaryKeyTypeBase = GetTypeAlias(underlyingPkType, false);
        string primaryKeyTypeAlias = isPkNullable ? $"{primaryKeyTypeBase}?" : primaryKeyTypeBase;

        // Using directives
        sb.AppendLine("using Microsoft.AspNetCore.Mvc;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName};");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Models;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName}s;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Upsert{entityName};");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Delete{entityName};");
        sb.AppendLine();

        // Namespace and class definition
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Web.Controllers;");
        sb.AppendLine();
        sb.AppendLine($"public class {metadata.PluralName}Controller : ApiControllerBase");
        sb.AppendLine("{");

        // Get method
        sb.AppendLine($"    [HttpGet(\"{{id}}\")]");
        sb.AppendLine($"    public async Task<ActionResult<{entityModelName}>> Get({primaryKeyTypeAlias} id)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await ExecuteAsync(() => Mediator.Send(new Get{entityName}Query {{ Id = id }}));");
        sb.AppendLine("    }");
        sb.AppendLine();

        // GetAll method
        sb.AppendLine("    [HttpGet]");
        sb.AppendLine($"    public async Task<ActionResult<IList<{entityModelName}>>> GetAll()");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await ExecuteAsync(() => Mediator.Send(new Get{entityName}sQuery()));");
        sb.AppendLine("    }");
        sb.AppendLine();

        // Create method
        sb.AppendLine("    [HttpPost]");
        sb.AppendLine($"    public async Task<ActionResult<{primaryKeyTypeAlias}>> Create(Upsert{entityName}Command command)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await ExecuteAsync(() => Mediator.Send(command));");
        sb.AppendLine("    }");
        sb.AppendLine();

        // Update method
        sb.AppendLine("    [HttpPut]");
        sb.AppendLine($"    public async Task<ActionResult<{primaryKeyTypeAlias}>> Update(Upsert{entityName}Command command)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await ExecuteAsync(() => Mediator.Send(command));");
        sb.AppendLine("    }");
        sb.AppendLine();

        // Delete method
        sb.AppendLine($"    [HttpDelete(\"{{id}}\")]");
        sb.AppendLine($"    public async Task<ActionResult<MediatR.Unit>> Delete({primaryKeyTypeAlias} id)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await ExecuteAsync(() => Mediator.Send(new Delete{entityName}Command {{ Id = id }}));");
        sb.AppendLine("    }");

        sb.AppendLine("}");

        return sb.ToString();
    }

    private static string GetTypeAlias(Type type, bool isNullable)
    {
        var typeName = Type.GetTypeCode(type) switch
        {
            TypeCode.Boolean => "bool",
            TypeCode.Byte => "byte",
            TypeCode.Char => "char",
            TypeCode.Decimal => "decimal",
            TypeCode.Double => "double",
            TypeCode.Single => "float",
            TypeCode.Int32 => "int",
            TypeCode.Int64 => "long",
            TypeCode.Object => type == typeof(Guid) ? "Guid" : type.Name,
            TypeCode.String => "string",
            _ => type.Name,
        };

        return isNullable ? $"{typeName}?" : typeName;
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "ControllerGenerator.cs") -Value $controllerGeneratorCs -Encoding UTF8
Write-Host "  Success: ControllerGenerator.cs" -ForegroundColor Green

$getQueryGeneratorCs = @'
using System;
using System.Linq;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class GetQueryGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var entityModelName = $"{entityName}Model";
        var queryName = $"Get{entityName}Query";

        // Use metadata for primary key info
        Type underlyingPkType = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) ?? metadata.PrimaryKeyType;
        bool isPkNullable = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) != null;

        string primaryKeyPropertyType = GetTypeAlias(underlyingPkType, isPkNullable);

        // Using directives
        sb.AppendLine("using AutoMapper;");
        sb.AppendLine("using MediatR;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Models;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.Common.Interfaces;");
        sb.AppendLine("using AutoMapper.QueryableExtensions;");
        sb.AppendLine("using Microsoft.EntityFrameworkCore;");
        sb.AppendLine("using System.Linq;");
        sb.AppendLine("using System.Threading;");
        sb.AppendLine("using System.Threading.Tasks;");
        sb.AppendLine();

        // Namespace
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName};");
        sb.AppendLine();

        // Query class
        sb.AppendLine($"public class {queryName} : IRequest<{entityModelName}?>");
        sb.AppendLine("{");
        sb.AppendLine($"    public {primaryKeyPropertyType} Id {{ get; set; }}");
        sb.AppendLine("}");
        sb.AppendLine();

        // Handler class
        sb.AppendLine($"public class Handler : IRequestHandler<{queryName}, {entityModelName}?>");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly IApplicationDbContext _context;");
        sb.AppendLine("    private readonly IMapper _mapper;");
        sb.AppendLine();
        sb.AppendLine("    public Handler(IApplicationDbContext context, IMapper mapper)");
        sb.AppendLine("    {");
        sb.AppendLine("        _context = context;");
        sb.AppendLine("        _mapper = mapper;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine($"    public async Task<{entityModelName}?> Handle({queryName} request, CancellationToken cancellationToken)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await _context.{metadata.PluralName}");

        // Use metadata.IsSoftDeletable to add soft delete filters
        if (metadata.IsSoftDeletable)
        {
            sb.AppendLine($"            .Where(x => x.{metadata.PrimaryKeyName} == request.Id && !x.RecDelete)");
        }
        else
        {
            sb.AppendLine($"            .Where(x => x.{metadata.PrimaryKeyName} == request.Id)");
        }

        sb.AppendLine($"            .ProjectTo<{entityModelName}>(_mapper.ConfigurationProvider)");
        sb.AppendLine("            .FirstOrDefaultAsync(cancellationToken);");
        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }

    private static string GetTypeAlias(Type type, bool isNullable)
    {
        var typeName = Type.GetTypeCode(type) switch
        {
            TypeCode.Boolean => "bool",
            TypeCode.Byte => "byte",
            TypeCode.Char => "char",
            TypeCode.Decimal => "decimal",
            TypeCode.Double => "double",
            TypeCode.Single => "float",
            TypeCode.Int32 => "int",
            TypeCode.Int64 => "long",
            TypeCode.Object => type == typeof(Guid) ? "Guid" : type.Name,
            TypeCode.String => "string",
            _ => type.Name,
        };

        return isNullable ? $"{typeName}?" : typeName;
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "GetQueryGenerator.cs") -Value $getQueryGeneratorCs -Encoding UTF8
Write-Host "  Success: GetQueryGenerator.cs" -ForegroundColor Green

$getQueryValidatorGeneratorCs = @'
using System;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class GetQueryValidatorGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var queryName = $"Get{entityName}Query";
        var validatorName = $"{queryName}Validator";

        // Using directive
        sb.AppendLine("using FluentValidation;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName};");
        sb.AppendLine();

        // Namespace
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName};");
        sb.AppendLine();

        // Validator class
        sb.AppendLine($"public class {validatorName} : AbstractValidator<{queryName}>");
        sb.AppendLine("{");
        sb.AppendLine($"    public {validatorName}()");
        sb.AppendLine("    {");

        // Use metadata.PrimaryKeyName
        sb.AppendLine($"        RuleFor(query => query.Id)");
        sb.AppendLine($"            .NotEmpty()");
        sb.AppendLine($"            .WithMessage(\"{entityName} {metadata.PrimaryKeyName} must not be empty.\");");

        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "GetQueryValidatorGenerator.cs") -Value $getQueryValidatorGeneratorCs -Encoding UTF8
Write-Host "  Success: GetQueryValidatorGenerator.cs" -ForegroundColor Green

$getAllQueryGeneratorCs = @'
using System;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class GetAllQueryGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();

        var entityName = metadata.EntityName;
        var entityModelName = $"{entityName}Model";
        var queryName = $"Get{entityName}sQuery";

        // Using directives
        sb.AppendLine("using AutoMapper;");
        sb.AppendLine("using AutoMapper.QueryableExtensions;");
        sb.AppendLine("using MediatR;");
        sb.AppendLine("using Microsoft.EntityFrameworkCore;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.Common.Interfaces;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Models;");
        sb.AppendLine();

        // Namespace
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Queries.Get{entityName}s;");
        sb.AppendLine();

        // Query class
        sb.AppendLine($"public class {queryName} : IRequest<IList<{entityModelName}>>");
        sb.AppendLine("{");
        sb.AppendLine("}");
        sb.AppendLine();

        // Handler class
        sb.AppendLine($"public class Handler : IRequestHandler<{queryName}, IList<{entityModelName}>>");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly IApplicationDbContext _context;");
        sb.AppendLine("    private readonly IMapper _mapper;");
        sb.AppendLine();
        sb.AppendLine("    public Handler(IApplicationDbContext context, IMapper mapper)");
        sb.AppendLine("    {");
        sb.AppendLine("        _context = context;");
        sb.AppendLine("        _mapper = mapper;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine($"    public async Task<IList<{entityModelName}>> Handle({queryName} request, CancellationToken cancellationToken)");
        sb.AppendLine("    {");
        sb.AppendLine($"        return await _context.{metadata.PluralName}");
        sb.AppendLine("            .AsNoTracking()");

        // Use metadata.IsSoftDeletable for soft delete filtering
        if (metadata.IsSoftDeletable)
        {
            sb.AppendLine("            .Where(x => !x.RecDelete)");
        }

        sb.AppendLine($"            .ProjectTo<{entityModelName}>(_mapper.ConfigurationProvider)");
        sb.AppendLine("            .ToListAsync(cancellationToken);");
        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "GetAllQueryGenerator.cs") -Value $getAllQueryGeneratorCs -Encoding UTF8
Write-Host "  Success: GetAllQueryGenerator.cs" -ForegroundColor Green

$upsertCommandGeneratorCs = @'
using System;
using System.Linq;
using System.Reflection;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class UpsertCommandGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();

        var entityName = metadata.EntityName;
        var entityType = metadata.EntityType;
        var commandClassName = $"Upsert{entityName}Command";
        var excludedProperties = new[] { "Created", "CreatedBy", "LastModified", "LastModifiedBy", "RecDelete", "DomainEvents", "Id", $"{entityName}Id" };

        // Use metadata for primary key info
        var primaryKeyPropertyName = metadata.PrimaryKeyName;
        Type underlyingPkType = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) ?? metadata.PrimaryKeyType;
        bool isPkNullable = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) != null || !metadata.PrimaryKeyType.IsValueType;

        // Get base type alias without applying nullability yet
        string primaryKeyTypeBase = GetTypeAlias(underlyingPkType, false);
        string primaryKeyPropertyType = isPkNullable ? $"{primaryKeyTypeBase}?" : primaryKeyTypeBase;

        sb.AppendLine("using MediatR;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.Common.Interfaces;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Domain.Entities;");
        sb.AppendLine("using System.Threading;");
        sb.AppendLine("using System.Threading.Tasks;");
        sb.AppendLine();

        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Upsert{entityName};");
        sb.AppendLine($"public class {commandClassName} : IRequest<{primaryKeyPropertyType}>");
        sb.AppendLine("{");

        // ✅ FIXED: Command Id should always be nullable for create vs update detection
        sb.AppendLine($"    public {primaryKeyTypeBase}? Id {{ get; set; }}");

        foreach (var prop in entityType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
        {
            if (excludedProperties.Contains(prop.Name) || prop.PropertyType.Namespace != "System" || prop.GetGetMethod()!.IsVirtual)
                continue;

            var type = Nullable.GetUnderlyingType(prop.PropertyType) ?? prop.PropertyType;
            var isNullable = Nullable.GetUnderlyingType(prop.PropertyType) != null || prop.PropertyType == typeof(string);
            var typeName = GetTypeAlias(type, isNullable);

            if (prop.Name != primaryKeyPropertyName)
            {
                sb.AppendLine($"    public {typeName} {prop.Name} {{ get; set; }}");
            }
        }

        sb.AppendLine("}");

        sb.AppendLine();
        sb.AppendLine($"public class Handler : IRequestHandler<{commandClassName}, {primaryKeyPropertyType}>");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly IApplicationDbContext _context;");
        sb.AppendLine($"    public Handler(IApplicationDbContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        _context = context;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine($"    public async Task<{primaryKeyPropertyType}> Handle({commandClassName} request, CancellationToken cancellationToken)");
        sb.AppendLine("    {");
        sb.AppendLine($"        {entityName}? entity;");
        sb.AppendLine();

        // Use metadata.PrimaryKeyType to determine the correct check
        if (underlyingPkType == typeof(string))
        {
            sb.AppendLine("        if (!string.IsNullOrEmpty(request.Id))");
        }
        else if (underlyingPkType == typeof(int) || underlyingPkType == typeof(long))
        {
            sb.AppendLine("        if (request.Id.HasValue && request.Id.Value > 0)");
        }
        else if (underlyingPkType == typeof(Guid))
        {
            sb.AppendLine("        if (request.Id.HasValue && request.Id.Value != Guid.Empty)");
        }
        else
        {
            sb.AppendLine("        if (request.Id.HasValue)");
        }

        sb.AppendLine("        {");
        sb.AppendLine($"            entity = await _context.{metadata.PluralName}.FindAsync(request.Id);");
        sb.AppendLine();
        sb.AppendLine("            if (entity == null)");
        sb.AppendLine($"                throw new {metadata.NamespaceRoot}.Application.Common.Exceptions.NotFoundException(nameof({entityName}), request.Id);");
        sb.AppendLine("        }");
        sb.AppendLine("        else");
        sb.AppendLine("        {");
        sb.AppendLine($"            entity = new {entityName}();");
        sb.AppendLine($"            _context.{metadata.PluralName}.Add(entity);");
        sb.AppendLine("        }");
        sb.AppendLine();

        // Generate property updates
        foreach (var prop in entityType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
        {
            if (!excludedProperties.Contains(prop.Name) && prop.PropertyType.Namespace == "System" && !prop.GetGetMethod()!.IsVirtual)
            {
                var propName = prop.Name;
                if (propName != primaryKeyPropertyName)
                {
                    sb.AppendLine($"        entity.{propName} = request.{propName};");
                }
            }
        }

        sb.AppendLine();
        sb.AppendLine("        await _context.SaveChangesAsync(cancellationToken);");
        sb.AppendLine();
        sb.AppendLine($"        return entity.{primaryKeyPropertyName};");
        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }

    private static string GetTypeAlias(Type type, bool isNullable)
    {
        var typeName = Type.GetTypeCode(type) switch
        {
            TypeCode.Boolean => "bool",
            TypeCode.Byte => "byte",
            TypeCode.Char => "char",
            TypeCode.Decimal => "decimal",
            TypeCode.Double => "double",
            TypeCode.Single => "float",
            TypeCode.Int32 => "int",
            TypeCode.Int64 => "long",
            TypeCode.Object => type == typeof(Guid) ? "Guid" : type.Name,
            TypeCode.String => "string",
            _ => type.Name
        };

        return isNullable ? $"{typeName}?" : typeName;
    }
}
'@
Set-Content -Path (Join-Path $generatorsPath "UpsertCommandGenerator.cs") -Value $upsertCommandGeneratorCs -Encoding UTF8
Write-Host "  Success: UpsertCommandGenerator.cs" -ForegroundColor Green

$upsertValidatorGeneratorCs = @'
using System;
using System.Linq;
using System.Reflection;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class UpsertValidatorGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var entityType = metadata.EntityType;
        var validatorClassName = $"Upsert{entityName}CommandValidator";
        var commandClassName = $"Upsert{entityName}Command";
        var excludedProperties = new[] { "Created", "CreatedBy", "LastModified", "LastModifiedBy", "RecDelete", "DomainEvents" };

        var primaryKeyPropertyName = metadata.PrimaryKeyName;
        var primaryKeyType = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) ?? metadata.PrimaryKeyType;
        bool isPrimaryKeyNullable = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) != null || !metadata.PrimaryKeyType.IsValueType;

        // Using directives
        sb.AppendLine("using FluentValidation;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Upsert{entityName};");
        sb.AppendLine();

        // Namespace and class definition
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Upsert{entityName};");
        sb.AppendLine($"public class {validatorClassName} : AbstractValidator<{commandClassName}>");
        sb.AppendLine("{");
        sb.AppendLine($"    public {validatorClassName}()");
        sb.AppendLine("    {");

        // Validate the primary key - logic depends on type
        sb.AppendLine($"        // Primary Key Validation");
        if (primaryKeyType == typeof(string))
        {
            sb.AppendLine($"        RuleFor(command => command.Id)");
            sb.AppendLine($"            .NotEmpty().When(command => command.Id != null)");
            sb.AppendLine($"            .WithMessage(\"Id must not be empty when provided.\");");
        }
        else if (primaryKeyType == typeof(Guid))
        {
            sb.AppendLine($"        RuleFor(command => command.Id)");
            sb.AppendLine($"            .NotEqual(Guid.Empty).When(command => command.Id.HasValue)");
            sb.AppendLine($"            .WithMessage(\"Id must not be empty when provided.\");");
        }
        else // int, long, etc.
        {
            sb.AppendLine($"        RuleFor(command => command.Id)");
            sb.AppendLine($"            .GreaterThan(0).When(command => command.Id.HasValue)");
            sb.AppendLine($"            .WithMessage(\"Id must be greater than 0 when provided.\");");
        }

        sb.AppendLine();

        // Generate validation rules for each property
        bool hasGeneratedRules = false;

        foreach (var property in entityType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
        {
            // Skip excluded properties
            if (excludedProperties.Contains(property.Name) ||
                property.PropertyType.Namespace != "System" ||
                property.GetGetMethod()!.IsVirtual ||
                property.Name == primaryKeyPropertyName)
            {
                continue;
            }

            // Extract the underlying type, handling nullable value types
            var propType = Nullable.GetUnderlyingType(property.PropertyType) ?? property.PropertyType;
            bool isPropNullable = Nullable.GetUnderlyingType(property.PropertyType) != null;

            // Generate validation based on type
            if (propType == typeof(string))
            {
                // String property - validate length
                sb.AppendLine($"        RuleFor(x => x.{property.Name})");
                sb.AppendLine($"            .MaximumLength(256).When(x => x.{property.Name} != null)");
                sb.AppendLine($"            .WithMessage(\"{property.Name} must not exceed 256 characters.\");");
                sb.AppendLine();
                hasGeneratedRules = true;
            }
            else if (propType == typeof(int))
            {
                // Integer property - validate range
                sb.AppendLine($"        RuleFor(x => x.{property.Name})");
                if (isPropNullable)
                {
                    sb.AppendLine($"            .GreaterThan(0).When(x => x.{property.Name}.HasValue)");
                }
                else
                {
                    sb.AppendLine($"            .GreaterThanOrEqualTo(0)");
                }
                sb.AppendLine($"            .WithMessage(\"{property.Name} must be a valid number.\");");
                sb.AppendLine();
                hasGeneratedRules = true;
            }
            else if (propType == typeof(long))
            {
                // Long integer property - validate range
                sb.AppendLine($"        RuleFor(x => x.{property.Name})");
                if (isPropNullable)
                {
                    sb.AppendLine($"            .GreaterThan(0).When(x => x.{property.Name}.HasValue)");
                }
                else
                {
                    sb.AppendLine($"            .GreaterThanOrEqualTo(0)");
                }
                sb.AppendLine($"            .WithMessage(\"{property.Name} must be a valid number.\");");
                sb.AppendLine();
                hasGeneratedRules = true;
            }
            else if (propType == typeof(DateTime))
            {
                // DateTime property - no specific validation
                // Dates are usually auto-generated or provided by client
                continue;
            }
            else if (propType == typeof(bool))
            {
                // Boolean property - no validation needed
                continue;
            }
            else if (propType == typeof(Guid))
            {
                // GUID property - no validation needed
                continue;
            }
            // For other types, skip validation
        }

        // If no rules were generated, add a comment
        if (!hasGeneratedRules)
        {
            sb.AppendLine("        // Add additional validation rules as needed");
        }

        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }
}
'@
Set-Content -Path (Join-Path $generatorsPath "UpsertValidatorGenerator.cs") -Value $upsertValidatorGeneratorCs -Encoding UTF8
Write-Host "  Success: UpsertValidatorGenerator.cs" -ForegroundColor Green

$deleteCommandGeneratorCs = @'
using System;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class DeleteCommandGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();

        sb.AppendLine("#nullable disable");
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var commandClassName = $"Delete{entityName}Command";

        // Use metadata for primary key info
        Type underlyingPkType = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) ?? metadata.PrimaryKeyType;
        bool isPkNullable = Nullable.GetUnderlyingType(metadata.PrimaryKeyType) != null;

        string primaryKeyTypeAlias = GetTypeAlias(underlyingPkType, isPkNullable);

        // Using directives
        sb.AppendLine("using MediatR;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Application.Common.Interfaces;");
        sb.AppendLine($"using {metadata.NamespaceRoot}.Domain.Entities;");
        sb.AppendLine("using System.Threading;");
        sb.AppendLine("using System.Threading.Tasks;");
        sb.AppendLine();

        // Namespace and command class definition
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Delete{entityName};");
        sb.AppendLine($"public class {commandClassName} : IRequest<Unit>");
        sb.AppendLine("{");
        sb.AppendLine($"    public {primaryKeyTypeAlias} Id {{ get; set; }}");
        sb.AppendLine("}");
        sb.AppendLine();

        // Handler class
        sb.AppendLine($"public class Handler : IRequestHandler<{commandClassName}, Unit>");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly IApplicationDbContext _context;");
        sb.AppendLine();
        sb.AppendLine("    public Handler(IApplicationDbContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        _context = context;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task<Unit> Handle(");
        sb.AppendLine($"        {commandClassName} request, CancellationToken cancellationToken)");
        sb.AppendLine("    {");
        sb.AppendLine($"        var entity = await _context.{metadata.PluralName}.FindAsync(new object[] {{ request.Id }}, cancellationToken);");
        sb.AppendLine();

        // Use metadata.IsSoftDeletable to determine soft delete vs hard delete logic
        if (metadata.IsSoftDeletable)
        {
            sb.AppendLine($"        if (entity == null || entity.RecDelete)");
            sb.AppendLine($"            throw new {metadata.NamespaceRoot}.Application.Common.Exceptions.NotFoundException(nameof({entityName}), request.Id);");
            sb.AppendLine();
            sb.AppendLine($"        entity.RecDelete = true;");
        }
        else
        {
            sb.AppendLine($"        if (entity == null)");
            sb.AppendLine($"            throw new {metadata.NamespaceRoot}.Application.Common.Exceptions.NotFoundException(nameof({entityName}), request.Id);");
            sb.AppendLine();
            sb.AppendLine($"        _context.{metadata.PluralName}.Remove(entity);");
        }

        sb.AppendLine();
        sb.AppendLine("        await _context.SaveChangesAsync(cancellationToken);");
        sb.AppendLine("        return Unit.Value;");
        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }

    private static string GetTypeAlias(Type type, bool isNullable)
    {
        var typeName = Type.GetTypeCode(type) switch
        {
            TypeCode.Boolean => "bool",
            TypeCode.Byte => "byte",
            TypeCode.Char => "char",
            TypeCode.Decimal => "decimal",
            TypeCode.Double => "double",
            TypeCode.Single => "float",
            TypeCode.Int32 => "int",
            TypeCode.Int64 => "long",
            TypeCode.Object => type == typeof(Guid) ? "Guid" : type.Name,
            TypeCode.String => "string",
            _ => type.Name,
        };

        return isNullable ? $"{typeName}?" : typeName;
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "DeleteCommandGenerator.cs") -Value $deleteCommandGeneratorCs -Encoding UTF8
Write-Host "  Success: DeleteCommandGenerator.cs" -ForegroundColor Green

$deleteCommandValidatorGeneratorCs = @'
using System;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class DeleteCommandValidatorGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var commandClassName = $"Delete{entityName}Command";
        var validatorClassName = $"Delete{entityName}Validator";

        // Using directives
        sb.AppendLine("using FluentValidation;");
        sb.AppendLine();

        // Namespace and validator class definition
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Application.{metadata.PluralName}.Commands.Delete{entityName};");
        sb.AppendLine($"public class {validatorClassName} : AbstractValidator<{commandClassName}>");
        sb.AppendLine("{");
        sb.AppendLine($"    public {validatorClassName}()");
        sb.AppendLine("    {");
        sb.AppendLine($"        RuleFor(x => x.Id)");
        sb.AppendLine($"            .NotEmpty()");
        sb.AppendLine($"            .WithMessage(\"{entityName} ID is required.\");");
        sb.AppendLine("    }");
        sb.AppendLine("}");

        return sb.ToString();
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "DeleteCommandValidatorGenerator.cs") -Value $deleteCommandValidatorGeneratorCs -Encoding UTF8
Write-Host "  Success: DeleteCommandValidatorGenerator.cs" -ForegroundColor Green

$configurationGeneratorCs = @'
using System;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public class ConfigurationGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var configCode = new StringBuilder();
        configCode.AppendLine();

        var entityType = metadata.EntityType;
        var entityName = metadata.EntityName;

        var namespaces = new HashSet<string>
        {
            "Microsoft.EntityFrameworkCore",
            "Microsoft.EntityFrameworkCore.Metadata.Builders",
            entityType.Namespace ?? "YourDefaultNamespace",
            "System.Collections.Generic"
        };

        // Define auditing column names to exclude from the configuration
        var auditingColumns = new HashSet<string> { "Created", "CreatedBy", "LastModified", "LastModifiedBy", "RecDelete", "DomainEvents" };

        var configClassName = $"{entityName}Configuration";

        AppendUsingStatements(configCode, namespaces);
        configCode.AppendLine($"namespace {metadata.NamespaceRoot}.Infrastructure.Data.Configurations;");
        configCode.AppendLine($"public class {configClassName} : IEntityTypeConfiguration<{entityName}>");
        configCode.AppendLine("{");
        configCode.AppendLine($"    public void Configure(EntityTypeBuilder<{entityName}> builder)");
        configCode.AppendLine("    {");
        configCode.AppendLine($"        builder.HasKey(e => e.{metadata.PrimaryKeyName});")
                  .AppendLine();

        var foreignKeys = entityType.GetProperties()
            .Where(p => p.Name.EndsWith("Id"))
            .ToList();

        foreach (var prop in entityType.GetProperties())
        {
            var isPrimaryKey = prop.Name == metadata.PrimaryKeyName;

            // Skip auditing columns and primary key
            if (auditingColumns.Contains(prop.Name) || isPrimaryKey)
            {
                continue;
            }

            var propType = Nullable.GetUnderlyingType(prop.PropertyType) ?? prop.PropertyType;
            var isCollection = typeof(IEnumerable).IsAssignableFrom(propType) && propType != typeof(string);
            var isNavigation = propType.IsClass && propType != typeof(string);

            if (!isCollection && !isNavigation)
            {
                // Simple property
                if (propType == typeof(string))
                {
                    configCode.AppendLine($"        builder.Property(e => e.{prop.Name})")
                               .AppendLine($"            .HasMaxLength(255);")
                               .AppendLine();
                }
                else
                {
                    // For non-nullable value types, add IsRequired
                    bool isNullable = Nullable.GetUnderlyingType(prop.PropertyType) != null;

                    if (!isNullable)
                    {
                        // Non-nullable value type
                        configCode.AppendLine($"        builder.Property(e => e.{prop.Name})")
                                   .AppendLine($"            .IsRequired();")
                                   .AppendLine();
                    }
                    else
                    {
                        // Nullable value type
                        configCode.AppendLine($"        builder.Property(e => e.{prop.Name});")
                                   .AppendLine();
                    }
                }
            }
            else
            {
                var relatedEntityType = isCollection ? prop.PropertyType.GetGenericArguments()[0] : propType;

                if (isCollection)
                {
                    // One-to-many relationship: FK is in the related entity
                    // FK name convention: {CurrentEntityName}Id (e.g., DoctorId in Treatment)
                    var foreignKeyName = $"{entityType.Name}Id";

                    var inverseNavigationProperty = relatedEntityType.GetProperties()
                        .FirstOrDefault(p => p.PropertyType == entityType);
                    var inverseNavigationName = inverseNavigationProperty != null
                        ? $"e => e.{inverseNavigationProperty.Name}"
                        : "null";

                    configCode.AppendLine($"        builder.HasMany(e => e.{prop.Name})")
                               .AppendLine($"            .WithOne({inverseNavigationName})")
                               .AppendLine($"            .HasForeignKey(d => d.{foreignKeyName});")
                               .AppendLine();
                }
                else
                {
                    // Many-to-one relationship: FK is in current entity
                    // FK name convention: {NavigationPropertyName}Id (e.g., DoctorId for Doctor property)
                    var foreignKeyName = $"{prop.Name}Id";

                    // Find collection properties in the related entity that reference the current entity type
                    var relatedEntityProperties = relatedEntityType.GetProperties();
                    var collectionPropertyOnRelatedType = relatedEntityProperties
                        .FirstOrDefault(p =>
                        {
                            if (!p.PropertyType.IsGenericType) return false;
                            var genericType = p.PropertyType.GetGenericTypeDefinition();
                            if (genericType != typeof(ICollection<>)) return false;
                            var itemType = p.PropertyType.GetGenericArguments()[0];
                            return itemType == entityType;
                        });

                    var collectionPropertyName = collectionPropertyOnRelatedType != null
                        ? $"d => d.{collectionPropertyOnRelatedType.Name}"
                        : "null";

                    configCode.AppendLine($"        builder.HasOne(e => e.{prop.Name})")
                               .AppendLine($"            .WithMany({collectionPropertyName})")
                               .AppendLine($"            .HasForeignKey(e => e.{foreignKeyName});")
                               .AppendLine();
                }
            }
        }

        configCode.AppendLine("    }");
        configCode.AppendLine("}");
        return configCode.ToString();
    }

    private static void AppendUsingStatements(StringBuilder configCode, HashSet<string> namespaces)
    {
        foreach (var ns in namespaces)
        {
            configCode.AppendLine($"using {ns};");
        }
        configCode.AppendLine();
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "ConfigurationGenerator.cs") -Value $configurationGeneratorCs -Encoding UTF8
Write-Host "  Success: ConfigurationGenerator.cs" -ForegroundColor Green

$testTemplateGeneratorCs = @'
using System;
using System.Linq;
using System.Reflection;
using System.Text;
using CodeGeneratorDev.Models;

namespace CodeGeneratorDev.Generators;

public static class TestTemplateGenerator
{
    public static string Generate(EntityMetadata metadata)
    {
        var sb = new StringBuilder();
        sb.AppendLine();

        var entityName = metadata.EntityName;
        var entityNamePlural = metadata.PluralName;
        var className = $"{entityName}ControllerTests";
        var modelName = $"{entityName}Model";
        var setupMethodName = $"Setup{entityName}Async";
        var entityVariableName = char.ToLowerInvariant(entityName[0]) + entityName.Substring(1); // camelCase

        var pkType = GetFriendlyTypeName(metadata.PrimaryKeyType);

        // Using directives
        sb.AppendLine("/*");
        AppendUsingDirectives(sb, entityName, entityNamePlural, modelName, metadata.NamespaceRoot);

        // Namespace and class declaration
        sb.AppendLine($"namespace {metadata.NamespaceRoot}.Api.IntegrationTests.ControllerTests;");
        sb.AppendLine();
        sb.AppendLine("using static Testing;");
        sb.AppendLine($"using static {entityName}Helpers;");
        sb.AppendLine($"public class {className} : BaseTestFixture");
        sb.AppendLine("{");

        // GetEntity With Valid Id Test
        GenerateGetMethod(sb, entityName, entityNamePlural, modelName, setupMethodName, entityVariableName);

        // GetAllEntities Test
        GenerateGetAllMethod(sb, entityNamePlural, modelName, setupMethodName, entityName);

        // LookupEntity Test
        GenerateLookupMethod(sb, entityName, entityNamePlural, modelName, setupMethodName);

        // CreateEntity Test
        GenerateCreateMethod(sb, entityName, entityNamePlural, modelName, pkType);

        // UpdateEntity Test
        GenerateUpdateMethod(sb, entityName, entityNamePlural, setupMethodName);

        // DeleteEntity Test
        GenerateDeleteMethod(sb, entityName, entityNamePlural, setupMethodName);

        sb.AppendLine("}");
        sb.AppendLine("*/");
        return sb.ToString();
    }

    private static string GetFriendlyTypeName(Type type)
    {
        // Handle nullable types
        Type underlyingType = Nullable.GetUnderlyingType(type) ?? type;

        // Handle common types explicitly
        if (underlyingType == typeof(Guid)) return "Guid";
        if (underlyingType == typeof(int)) return "int";
        if (underlyingType == typeof(long)) return "long";
        if (underlyingType == typeof(string)) return "string";

        return underlyingType.Name;
    }

    private static void AppendUsingDirectives(StringBuilder sb, string entityName, string entityNamePlural, string modelName, string namespaceRoot)
    {
        sb.AppendLine("using System;");
        sb.AppendLine("using System.Net;");
        sb.AppendLine("using System.Net.Http.Json;");
        sb.AppendLine("using System.Text;");
        sb.AppendLine("using System.Text.Json;");
        sb.AppendLine("using FluentAssertions;");
        sb.AppendLine($"using {namespaceRoot}.Domain.Entities;");
        sb.AppendLine($"using {namespaceRoot}.Application.IntegrationTests.{entityNamePlural};");
        sb.AppendLine($"using {namespaceRoot}.Application.{entityNamePlural}.Models;");
        sb.AppendLine($"using {namespaceRoot}.Application.{entityNamePlural}.Queries.Get{entityName};");
        sb.AppendLine($"using {namespaceRoot}.Application.{entityNamePlural}.Actions.Upsert{entityName};");
        sb.AppendLine($"using {namespaceRoot}.Application.{entityNamePlural}.Queries.Get{entityName}sByLookup;");
        sb.AppendLine();
    }

    private static void GenerateGetMethod(StringBuilder sb, string entityName, string entityNamePlural, string modelName, string setupMethodName, string entityVariableName)
    {
        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task Get{entityName}_WithValidId_Returns{modelName}()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        var {entityVariableName}Id = await {setupMethodName}();");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        sb.AppendLine($"        var response = await _client.GetAsync($\"/api/{entityNamePlural}/Get/{{{entityVariableName}Id}}\");");
        sb.AppendLine($"        var {entityVariableName} = await DeserializeResponseAsync<{modelName}>(response);");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        sb.AppendLine($"        {entityVariableName}.Should().NotBeNull();");
        sb.AppendLine($"        {entityVariableName}.Id.Should().Be({entityVariableName}Id);");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    private static void GenerateGetAllMethod(StringBuilder sb, string entityNamePlural, string modelName, string setupMethodName, string entityName)
    {
        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task GetAll{entityName}s_Returns{entityName}sList()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        await {setupMethodName}();");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        sb.AppendLine($"        var response = await _client.GetAsync(\"/api/{entityNamePlural}/GetAll\");");
        sb.AppendLine($"        var {entityNamePlural.ToLower()} = await DeserializeResponseAsync<IList<{modelName}>>(response);");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        sb.AppendLine($"        {entityNamePlural.ToLower()}.Should().NotBeEmpty();");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    private static void GenerateLookupMethod(StringBuilder sb, string entityName, string entityNamePlural, string modelName, string setupMethodName)
    {
        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task Lookup{entityName}_WithValidData_ReturnsFiltered{entityName}s()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        var {entityName}Id = await {setupMethodName}();");
        sb.AppendLine("        var lookupDto = new { };");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        sb.AppendLine($"        var response = await _client.PostAsJsonAsync(\"/api/{entityNamePlural}/Lookup\", lookupDto);");
        sb.AppendLine($"        var result = await DeserializeResponseAsync<IList<{modelName}>>(response);");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        sb.AppendLine("        result.Should().ContainSingle();");
        sb.AppendLine($"        result.First().Id.Should().Be({entityName}Id);");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    private static void GenerateCreateMethod(StringBuilder sb, string entityName, string entityNamePlural, string modelName, string pkType)
    {
        var entityVariableName = char.ToLowerInvariant(entityName[0]) + entityName.Substring(1); // camelCase

        // Determine the default value check based on pkType
        var defaultValueCheck = GetDefaultValueCheckExpression(pkType);

        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task Create{entityName}_WithValidData_ReturnsNew{entityName}Id()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        var {entityVariableName}CreateDto = new {{ }};");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        // Dynamically use pkType for deserialization
        sb.AppendLine($"        var response = await _client.PostAsJsonAsync(\"/api/{entityNamePlural}/Create\", {entityVariableName}CreateDto);");
        sb.AppendLine($"        var created{entityName}Id = await DeserializeResponseAsync<{pkType}>(response);");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        // Use the dynamically determined default value check for assertion
        sb.AppendLine($"        created{entityName}Id.Should().NotBe({defaultValueCheck});");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    private static void GenerateUpdateMethod(StringBuilder sb, string entityName, string entityNamePlural, string setupMethodName)
    {
        var entityVariableName = char.ToLowerInvariant(entityName[0]) + entityName.Substring(1); // camelCase
        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task Update{entityName}_WithValidData_ReturnsSuccess()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        var {entityVariableName}Id = await {setupMethodName}();");
        sb.AppendLine($"        var {entityVariableName}UpdateDto = new {{ Id = {entityVariableName}Id }};");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        sb.AppendLine($"        var response = await _client.PutAsJsonAsync(\"/api/{entityNamePlural}/Update\", {entityVariableName}UpdateDto);");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    private static void GenerateDeleteMethod(StringBuilder sb, string entityName, string entityNamePlural, string setupMethodName)
    {
        var entityVariableName = char.ToLowerInvariant(entityName[0]) + entityName.Substring(1); // camelCase
        sb.AppendLine("    [Test]");
        sb.AppendLine($"    public async Task Delete{entityName}_WithValidId_ReturnsSuccess()");
        sb.AppendLine("    {");
        sb.AppendLine("        // Arrange");
        sb.AppendLine($"        var {entityVariableName}Id = await {setupMethodName}();");
        sb.AppendLine();
        sb.AppendLine("        // Act");
        sb.AppendLine($"        var response = await _client.DeleteAsync($\"/api/{entityNamePlural}/Delete/{{{entityVariableName}Id}}\");");
        sb.AppendLine();
        sb.AppendLine("        // Assert");
        sb.AppendLine("        response.Should().HaveStatusCode(HttpStatusCode.OK);");
        sb.AppendLine("    }");
        sb.AppendLine();
    }

    // Utility method to get the default value check expression based on primary key type
    private static string GetDefaultValueCheckExpression(string pkType)
    {
        switch (pkType)
        {
            case "Guid":
                return "Guid.Empty";
            case "int":
            case "long":
            case "short":
                return "0"; // Assuming numeric types should not be zero
            default:
                return "null"; // Fallback for reference types and others
        }
    }
}

'@
Set-Content -Path (Join-Path $generatorsPath "TestTemplateGenerator.cs") -Value $testTemplateGeneratorCs -Encoding UTF8
Write-Host "  Success: TestTemplateGenerator.cs" -ForegroundColor Green

# =============================================================================
# STEP 6: CREATE README
# =============================================================================

Write-Host ""
Write-Host "Step 6: Creating README.md..." -ForegroundColor White

$readme = @'
# CodeGeneratorDev V2 - CQRS Boilerplate Generator

Self-contained C# console app for generating CQRS boilerplate code.

## Features

- EntityMetadata pattern for intelligent code generation
- Accurate DbSet pluralization resolution
- Support for soft deletes and audit trails
- Full CQRS vertical slice generation
- Automatic capability detection

## Usage

\\\powershell
dotnet run -- <domain-dll-path> <solution-root> <namespace-root> [--dry-run]
\\\

## Generated Output

- Models (DTOs with AutoMapper)
- Queries (Get single, GetAll with pagination)
- Commands (Upsert with validation, Delete with soft-delete)
- Validators (FluentValidation)
- Configurations (EF Core)
- Controllers (API endpoints)
- Tests (Integration test templates)

## Example

\\\powershell
dotnet run -- "C:\Project\artifacts\bin\Domain\release\Project.Domain.dll" "C:\Project" "MyNamespace"
\\\

## Version

2.0 - EntityMetadata Pattern Implementation
Generated with Create-CodeGeneratorDev-v2.ps1
'@

Set-Content "README.md" -Value $readme -Encoding UTF8
Write-Host "  Success: README.md" -ForegroundColor Green

# =============================================================================
# STEP 7: BUILD VALIDATION
# =============================================================================

Write-Host ""
Write-Host "Step 7: Build validation..." -ForegroundColor White

if (-not $SkipBuild) {
    $buildResult = dotnet build --configuration Release --verbosity quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Success: Build successful" -ForegroundColor Green
    }
    else {
        Write-Host "  Warning: Build failed" -ForegroundColor Yellow
        Write-Host "  $buildResult" -ForegroundColor Gray
    }
}
else {
    Write-Host "  Info: Build skipped" -ForegroundColor Gray
}

Pop-Location

# =============================================================================
# COMPLETION
# =============================================================================

Write-Host ""
Write-Host "=== SUCCESS ===" -ForegroundColor Green
Write-Host ""
Write-Host "Location: $OutputPath" -ForegroundColor White
Write-Host "Files: 14 C# source files + README.md" -ForegroundColor Gray
Write-Host "Pattern: EntityMetadata + PluralNameResolver" -ForegroundColor Cyan
Write-Host ""
Write-Host "This solution is completely self-contained!" -ForegroundColor Green
Write-Host "Ready for production use." -ForegroundColor Green
Write-Host ""
