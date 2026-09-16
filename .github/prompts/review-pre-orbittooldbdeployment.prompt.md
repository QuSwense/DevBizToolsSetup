---
description: Perform a pre-deployment consistency review of current OrbitToolDatabase dbo SQL changes.
---

Review the current OrbitToolDatabase dbo SQL changes for deployment risks.

Determine what changed and inspect the affected dependency graph.

Check:

- Table changes
- Column changes
- Data-type changes
- Nullability changes
- Primary keys
- Foreign keys
- Constraints
- Indexes
- Stored procedures
- Views
- Functions
- Dependencies
- Circular references
- Seed implications
- Supporting-script implications

Pay particular attention to changes that can cause:

- Deployment ordering problems
- Broken object creation
- Invalid stored procedures
- Invalid views
- Invalid functions
- Foreign-key failures
- Seed failures
- Data truncation
- Type conversion problems

Do not modify files.

Provide:

## Changes Detected

## Deployment Risks

## Errors

## Warnings

## Recommendations

## Affected Objects

## Supporting Script Impact

Do not apply changes without explicit user approval.