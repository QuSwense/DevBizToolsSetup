---
name: orbit-db-schema
description: Review OrbitToolDatabase SQL Server table schemas, columns, data types, lengths, precision, scale, nullability, keys, constraints, relationships, indexes, and schema consistency. Use when reviewing tables or schema changes.
---

# OrbitTool Database Schema Review

Use this skill when reviewing or designing SQL Server tables under:

`OrbitToolDatabase/dbo/Tables`

## Source of Truth

Treat the repository SQL files as the primary definition of the intended schema.

Use the live `OrbitTool` database as a verification source when database metadata is required.

Live database investigation must be read-only during review.

## Table Review

For each relevant table, review:

- Table name and purpose
- Column names
- SQL Server data types
- Length, precision, and scale
- NULL / NOT NULL
- Identity properties
- Computed columns
- Primary keys
- Foreign keys
- UNIQUE constraints
- CHECK constraints
- DEFAULT constraints
- Indexes
- Audit columns where applicable

Check whether columns and constraints correctly represent the intended entity and relationships.

## Primary Keys

Verify that each appropriate table has a clear primary key.

Check:

- Key column selection
- Data type
- Identity behavior where applicable
- Composite-key design where relevant
- Consistency with referencing foreign keys

Do not recommend changing an established key merely because another design could also work. Distinguish a genuine structural problem from a design recommendation.

## Foreign Keys and Relationships

Verify:

- Referenced table and column
- Referencing table and column
- Data-type compatibility
- NULL behavior
- Referential integrity
- Delete/update behavior where explicitly defined

Consider whether the relationship represented by the foreign key matches the logical relationship between the entities.

## Constraints

Review whether constraints enforce important database invariants.

Consider:

- UNIQUE constraints
- CHECK constraints
- DEFAULT constraints
- NULLability
- Referential constraints

Do not assume that every possible business rule belongs in the database. Identify missing enforcement as a recommendation unless the repository requirements clearly establish it as a defect.

## Data Types

Check whether the selected SQL Server data types are appropriate for the stored data.

Pay particular attention to:

- Integer ranges
- String lengths
- Unicode vs non-Unicode strings
- Decimal precision and scale
- Date/time types
- Binary data
- Boolean-like columns
- Identifier columns

Avoid changing a type solely for stylistic preference.

## Indexes

Review indexes relevant to:

- Primary keys
- Foreign keys
- Frequently queried columns
- Unique requirements
- Sorting/filtering patterns
- Multi-column access patterns

Consider duplicate or overlapping indexes and indexes that may not provide meaningful value.

## Consistency

Compare logically equivalent structures across related tables.

Look for inconsistent:

- Identifier naming
- Data types
- Lengths
- Nullability
- Audit columns
- Key patterns
- Foreign-key patterns

Consistency should be evaluated in context rather than enforced mechanically.

## Circular Relationships

Identify relationships that create cycles between tables.

Examples:

`A -> B -> A`

`A -> B -> C -> A`

Determine whether the cycle is intentional and whether it introduces:

- Insert-order problems
- Delete-order problems
- Deployment difficulty
- Referential-integrity complications

Distinguish an intentional domain relationship from an actual implementation problem.

## Findings

Classify findings as:

- `DEFECT` — incorrect, broken, or unsafe schema behavior
- `INCONSISTENCY` — conflicts with an established repository pattern
- `CONVENTION` — naming or structural convention issue
- `RECOMMENDATION` — possible improvement that is not currently a defect

Never present a recommendation as a confirmed defect without evidence.

## Schema Changes

When reviewing a proposed schema change, consider its effect on:

- Existing foreign keys
- Stored procedures
- Views
- Functions
- Indexes
- Seed data
- Reset/recreate scripts
- Column descriptions
- Other repository SQL scripts

The actual change must still follow the owning agent's approval workflow.