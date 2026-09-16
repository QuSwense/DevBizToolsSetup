---
name: orbit-db-naming
description: Apply and review OrbitToolDatabase SQL Server naming conventions for tables, stored procedures, views, functions, columns, and SQL script filenames. Use when reviewing object names or proposing new database objects.
---

# OrbitTool Database Naming Conventions

Use this skill when reviewing or proposing SQL Server object names.

## Source of Truth

Existing OrbitToolDatabase repository conventions are the primary source of truth.

Do not introduce a new naming pattern when an established repository pattern already exists.

## Stored Procedures

Stored procedures use the:

`usp_`

prefix.

The established pattern is:

`usp_<Operation><MainTableOrEntity><OptionalPurpose>`

Examples of operation-oriented naming include:

- `usp_Get...`
- `usp_Find...`
- `usp_Insert...`
- `usp_Update...`
- `usp_Delete...`

Use the main entity represented by the procedure rather than arbitrary implementation terminology.

## Views

Views use the:

`v_`

prefix.

The established pattern is:

`v_<MainTableOrEntity><Purpose>`

Examples include views representing:

- Summaries
- Detailed information
- Combined entity information

A view involving multiple tables is not automatically a naming violation.

## Functions

Review function names against the existing repository pattern.

Do not create a new function naming convention when an established convention already exists.

## Filenames and Object Names

Where practical, SQL filenames should correspond clearly to the database object they define.

Check consistency between:

- File name
- SQL object name
- Object type
- Repository directory

Examples:

```text
dbo/Tables/<TableName>.sql
dbo/Views/v_<ViewName>.sql
dbo/StoredProcedures/usp_<ProcedureName>.sql
dbo/Functions/<FunctionName>.sql