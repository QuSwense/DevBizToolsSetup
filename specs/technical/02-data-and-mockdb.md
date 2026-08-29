# 02. Data and Mock Database Specification

## Data source model

The application uses a mixed data model:

- relational database context registration for selected feature domains
- mock JSON seed files for feature operational data
- singleton store services that load and persist records for UI-driven workflows

## Mock database layout

The mock database lives under `mock_db/` and is grouped by domain:

- `Dashboard/`
- `Rest/`
- `Soap/`
- `Wsdl/`

These folders include data for applications, request files, execution history, templates, and sync records. The `MockDbLoader` service resolves the configured `MockDb:Path` and loads files from the configured directory.

## Configuration rules

The current app configuration expects the mock path to be defined in the web host configuration and resolved by `IConfiguration` only. The app is designed to fail fast if the value is missing, empty, or points to a non-existent directory.

## Persistence behavior

Feature stores are responsible for:

- loading JSON records at startup or on demand
- mutating the in-memory set for UI actions
- saving back to the configured mock JSON file when the workflow requires persistence

The business spec for the SOAP feature explicitly covers execution history and test-case persistence; engine-driven flows are designed to keep file-level records and request metadata in sync.

## Data integrity expectations

- Deletes should cascade through dependent mock content when a parent feature record is removed.
- Execution history should be retained when a parent app is removed, unless the feature intentionally defines a destructive cascade.
- Persisted file and template changes should remain consistent with the route-specific UI workflows.
