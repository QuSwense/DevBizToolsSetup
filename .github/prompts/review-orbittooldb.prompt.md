Review the current OrbitToolDatabase dbo SQL scripts.

Perform a database-wide read-only review of the current repository state.

Start by inspecting:
- complete-files.txt
- OrbitToolDatabase/dbo/

Build an inventory of the current dbo SQL objects and then review them in
manageable groups.

Review:

1. Tables
   - Columns
   - Data types
   - Lengths
   - Precision/scale
   - Nullability
   - Primary keys
   - Foreign keys
   - Unique constraints
   - Check constraints
   - Default constraints
   - Indexes

2. Relationships
   - FK consistency
   - Missing or incorrect relationships
   - Circular references
   - Dependency/deployment issues

3. Stored Procedures
   - References to tables/columns
   - Parameter compatibility
   - Data-type/size consistency
   - Main-table naming
   - Naming convention
   - Potential SQL problems

4. Views
   - Referenced tables/columns
   - JOIN correctness
   - Duplicate-row risks
   - Cartesian joins
   - Data-type issues
   - Naming convention

5. Functions
   - Dependencies
   - Parameter/return types
   - Invalid references
   - Naming consistency

6. Cross-object consistency
   - Same logical column with different types
   - Different sizes
   - Different precision/scale
   - PK/FK incompatibilities
   - Obsolete references
   - Filename/object-name mismatches

7. Naming conventions
   - Stored procedures should follow the repository's established usp_ pattern
   - Views should follow the repository's established v_ pattern
   - The main table/entity should normally be identifiable where applicable

8. Indexes
   - Duplicate indexes
   - Overlapping indexes
   - Missing potentially useful indexes
   - Obvious indexing concerns

Classify every finding as:

ERROR
WARNING
CONVENTION
RECOMMENDATION

Important:

- Do not modify any files.
- Do not modify the live OrbitTool database.
- Use MCP only for read-only database inspection.
- Do not execute CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, MERGE,
  TRUNCATE, or other state-changing SQL.
- Use the actual repository conventions rather than inventing conventions.
- Do not treat every difference as an error.
- Distinguish confirmed defects from recommendations.
- Do not make changes yet.

For every significant finding provide:

- Classification
- File
- Object
- Relevant table/column
- Evidence
- Explanation
- Suggested resolution

Also identify any files under:

OrbitToolDatabase/scripts/
OrbitToolDatabase/Seeds/

that may be affected by dbo findings, but do not modify them.

Those supporting-script changes will be handled separately by
OrbitToolSqlManager.

Finally produce:

## Review Scope

## Object Inventory

## Errors

## Warnings

## Naming / Convention Findings

## Relationship and Constraint Findings

## Stored Procedure Findings

## View Findings

## Function Findings

## Index Findings

## Dependency / Circular Reference Findings

## Cross-Object Consistency Findings

## Recommendations

## Supporting Script Impact

## Proposed Changes

Do not apply any proposed changes until I explicitly approve them.