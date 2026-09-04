# 03. Rest API Test

## Purpose

The REST API Test feature manages the REST API application catalog, request files, Swagger sync workflow, reusable templates, execution history, test cases, and execution rules.

## Primary routes

- `/rest/applications`
- `/rest/request-files`
- `/rest/swagger-sync`
- `/rest/templates`
- `/rest/execute-history`
- `/rest/test-cases` — dedicated per application and per request file
- `/rest/rules` — execution rule management

## Core business outcomes

- Manage REST application definitions.
- Organize request files and request execution history.
- Track Swagger/OpenAPI sync data.
- Reuse templates and review API behavior across request executions.
- **Test Cases:** Dedicated test case definitions scoped per application and per request file, enabling structured validation of REST responses.
- **Execution Rules:** Custom and global evaluation rules for automated pass/fail determination on REST responses.
- **Rule Application:** Test cases support attaching new custom rules or linking common global rules for automated evaluation without manual inspection.

## Current implementation anchors

- `Features/OrbitHub.RestApplications/Pages/`
- `Features/OrbitHub.RestApplications/DependencyInjection.cs`
- `Infrastructure/OrbitHub.Data/RestManagement/` (RestDbContext, repositories)
