---
name: orbithub-data-schema-to-cs-sync
description: Generate or sync OrbitHub.Data C# Repositories, Models, and Views from SQL schema
agent: OrbitHubDataSchemaToCsSync
---

Generate and synchronize C# classes for entity **${input:entityName}** in module **${input:moduleName=ServiceAppManagement}** against the `OrbitTool` SQL schema.

Target Locations:
- Models: `Infrastructure/OrbitHub.Data/${input:moduleName}/Models/*${input:entityName}*.cs`
- Repositories: `Infrastructure/OrbitHub.Data/${input:moduleName}/Repositories/*${input:entityName}*Repository.cs`
- Views: `Infrastructure/OrbitHub.Data/${input:moduleName}/Views/*${input:entityName}*View.cs`

Execution Steps:
1. Query `mssql-mcp` for procedures matching `usp_*${input:entityName}*`, views matching `v_*${input:entityName}*`, or tables matching `${input:entityName}`.
2. Outline existing C# files using `tokensaver` to check current properties and signatures.
3. Create or update Input/Output models with `required` properties, file-scoped namespaces, and types mapped cleanly to SQL data types.
4. Create or update Repository and View classes to match the schema definitions.
5. Print a concise bulleted summary of generated/modified files and property changes, then stop.