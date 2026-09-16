---
name: orbit-db-dependencies
description: Analyze OrbitToolDatabase SQL Server object dependencies across tables, foreign keys, stored procedures, views, functions, constraints, and indexes. Use when reviewing object impact, dependency chains, circular references, or deployment order.
---

# OrbitTool Database Dependency Analysis

Use this skill when determining dependencies or the impact of a database change.

## Sources

Dependency analysis can use:

- Repository SQL files
- Repository-wide text/search results
- SQL Server metadata
- Read-only database MCP investigation

The repository SQL definitions should be considered alongside live database metadata when both are available.

## Dependency Types

Track dependencies including:

- Table -> Table
- Foreign Key -> Table
- Stored Procedure -> Table/View
- View -> Table/View
- Function -> Table/View
- Constraint -> Table
- Index -> Table

Also identify indirect dependencies where practical.

## Dependency Investigation

When a database object changes, identify objects that may depend on it.

For a table change, consider:

`Table`
-> `Foreign Keys`
-> `Stored Procedures`
-> `Views`
-> `Functions`
-> `Indexes`
-> `Seeds`
-> `Supporting Scripts`

For an object such as a stored procedure or view, identify its underlying tables and other referenced objects.

## Repository Search

Search the repository for:

- Object names
- Table names
- Procedure names
- View names
- Function names
- Foreign-key references
- Relevant column names

Do not assume that database metadata alone represents all repository dependencies. SQL files and orchestration scripts may contain dependencies that need repository-level inspection.

## Circular Dependencies

Look for cycles such as:

`A -> B -> A`

or:

`A -> B -> C -> A`

Determine whether the cycle affects:

- Creation order
- Drop order
- Reset/recreate execution
- Data loading order
- Foreign-key creation
- Seed execution

A dependency cycle is not automatically a defect. Record the concrete operational impact before classifying it.

## Change Impact

For a proposed change, identify:

### Direct Impact

Objects that directly reference the changed object.

### Indirect Impact

Objects affected through another dependent object.

### Operational Impact

Supporting scripts or deployment sequences that may require modification.

## Deployment Considerations

When dependencies affect deployment, consider:

- Object creation order
- Foreign-key creation order
- Object drop order
- Seed execution order
- Reset/recreate sequence
- Required intermediate steps

Do not alter deployment scripts merely because a dependency exists. First determine whether the existing orchestration already handles it.

## Findings

Use concrete dependency evidence.

Distinguish between:

- Confirmed dependency
- Potential dependency requiring verification
- Circular dependency
- Deployment-order concern
- Recommendation

Do not infer a dependency solely from similar names.