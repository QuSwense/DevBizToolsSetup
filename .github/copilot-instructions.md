# GitHub Copilot Instructions

## Core Workflow & Scope Control
- **Targeted Operations Only:** Never perform open-ended exploration. Do not dump or inspect entire directories at once.
- **Narrow File Reads:** Limit file reads to relevant classes or methods. Do not ingest full files when checking schema mappings or signatures.
- **Strict Grep Queries:** Avoid broad search patterns. Filter searches specifically by symbol name, file type, or direct path to prevent oversized buffers (>20KB).
- **Subtask Execution:** Complete database/schema alignment tasks incrementally per entity or module. Stop and report status rather than chaining unbounded file updates in a single turn.

## C# & .NET Code Standards
- **Architecture & DI:** Use Primary Constructors for Dependency Injection (.NET 8 / C# 12).
- **Models & DTOs:** Use `required` properties on all DTOs and entity input/output models (.NET 7 / C# 11).
- **Accessors:** Use the `field` contextual keyword for custom property accessors (.NET 10 / C# 14).
- **Syntax Modernization:**
  - Prefer Collection Expressions `[]` (.NET 8 / C# 12) over legacy array/collection initializations.
  - Use Raw String Literals (`"""..."""`) for SQL queries, multi-line strings, and escaped payloads (.NET 7 / C# 11).
  - Use File-Scoped Namespaces across all C# files (.NET 6 / C# 10).
- **Naming & Conventions:**
  - `PascalCase` for public properties, types, and methods.
  - `_camelCase` for private fields.
  - Async methods must strictly append the `Async` suffix.
  - Use `// <summary>` XML documentation for public APIs and contracts.
  - Enforce a maximum line length of 120 characters.

## SQL & Data Layer Alignment
- Treat stored procedures (`usp_*`) and views (`v_*`) as the strict source of truth for input/output shapes.
- Only update Repository, Input, and Output classes directly impacted by the schema change. Do not alter surrounding unrelated infrastructure code.
- Provide a brief bulleted summary of changed fields and files upon completion.
