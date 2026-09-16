---
description: Analyze the impact of a table or table-column change across the OrbitToolDatabase project.
---

Analyze the requested table or column change.

Use a dependency-driven investigation.

First inspect the table definition and then identify affected:

- Foreign keys
- Related tables
- Stored procedures
- Views
- Functions
- Constraints
- Indexes
- Other repository references

Check for:

- Data-type inconsistencies
- Size inconsistencies
- Nullability problems
- Broken references
- Circular dependencies
- Stored procedure incompatibilities
- View incompatibilities
- Naming issues
- Seed impact
- Supporting-script impact

Do not modify files.

Report:

## Changed Object

## Direct Dependencies

## Dependent Objects

## Errors

## Warnings

## Convention Findings

## Recommendations

## Proposed Changes

## Supporting Script Impact

Wait for explicit approval before modifying any dbo SQL files.