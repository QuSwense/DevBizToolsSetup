# 03. Rest API Test

## Purpose

The REST API Test feature manages the REST API application catalog, request files, Swagger sync workflow, reusable templates, and execution history.

## Primary routes

- `/rest/applications`
- `/rest/request-files`
- `/rest/swagger-sync`
- `/rest/templates`
- `/rest/execute-history`

## Core business outcomes

- Manage REST application definitions.
- Organize request files and request execution history.
- Track Swagger/OpenAPI sync data.
- Reuse templates and review API behavior across request executions.

## Current implementation anchors

- `Features/ServiceHubEnterprise.RestApplications/Pages/`
- `Features/ServiceHubEnterprise.RestApplications/DependencyInjection.cs`
- `mock_db/Rest/`
