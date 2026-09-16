---
name: orbithub-data-schema-to-cs-sync
description: Sync OrbitHub.Data C# Repositories, Models, and Views with OrbitToolDatabase SQL schema
agent: OrbitHubDataSchemaToCsSync
---

Synchronize data layer classes for entity **${input:entityName}** in module **${input:moduleName=ServiceAppManagement}**.

Workspace Paths:
- Procedures: `OrbitToolDatabase/dbo/StoredProcedures/usp_*${input:entityName}*.sql`
- Tables: `OrbitToolDatabase/dbo/Tables/*${input:entityName}*.sql`
- SQL Views: `OrbitToolDatabase/dbo/Views/v_*${input:entityName}*.sql`
- C# Models: `Infrastructure/OrbitHub.Data/${input:moduleName}/Models/` (or root of module if no Models/ folder exists)
- C# Repositories: `Infrastructure/OrbitHub.Data/${input:moduleName}/Repositories/`
- C# Views: `Infrastructure/OrbitHub.Data/${input:moduleName}/Views/`

Workflow:
1. Fetch parameter and column definitions via `mssql-mcp` for `usp_*${input:entityName}*`, `v_*${input:entityName}*`, and `${input:entityName}` tables. If unavailable, inspect only the signature and SELECT projection of the matching SQL files above.
2. Outline matching C# classes with `tokensaver` to evaluate missing properties and parameter discrepancies.
3. Update Input/Output models, View classes (`*View.cs`), and Repositories (`*Repository.cs`, `*ViewRepository.cs`) to match the SQL contract.
4. Print a concise bulleted summary of updated files and property changes, then stop.