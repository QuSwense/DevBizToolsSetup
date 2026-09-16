---
name: orbittool-sql-manager
description: Query, validate, update, or sync OrbitTool database schema objects
agent: OrbitToolSqlManager
---

Perform the requested operation on entity **${input:entityName}** (Action: **${input:action=validate}**).

Target Paths:
- Table: `OrbitToolDatabase/dbo/Tables/*${input:entityName}*.sql`
- Stored Procedures: `OrbitToolDatabase/dbo/StoredProcedures/usp_*${input:entityName}*.sql`
- Views: `OrbitToolDatabase/dbo/Views/v_*${input:entityName}*.sql`
- Orchestration: `OrbitToolDatabase/scripts/`

Workflow:
1. **Live Schema Inspection:** Use `mssql-mcp` to retrieve current metadata (columns, constraints, parameters) for `${input:entityName}` from the `OrbitTool` database.
2. **Script Comparison:** Inspect matching local `.sql` definitions in `OrbitToolDatabase/dbo/` to verify alignment with live database objects.
3. **Execution Mode:**
   - `validate`: Report column, data type, nullability, or constraint discrepancies between the database engine and the local `.sql` files.
   - `update`: Update the local `.sql` files using `replace_string_in_file` to match the target schema changes.
   - `query`: Run read-only queries using `mcp_mssql-mcp_execute_sql` to inspect data or schema definitions.
4. **Summary & Maintenance:** Output a concise bulleted list of verified items or changed files. If database re-seeding or script execution is needed, provide the exact `OrbitToolDatabase/scripts/OrbitTool_SQLCMD.sh` command for the user to run.
5. **Error Handling:** Clearly indicate any discrepancies, failed updates, or query errors, and suggest corrective actions.