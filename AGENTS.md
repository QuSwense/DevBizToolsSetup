# AGENTS.md

This repository keeps agent guidance intentionally lightweight. The detailed business and technical specifications live in the `specs/` folder and should be treated as the source of truth.

## Authoritative specs

- `specs/README.md` — full index for the numbered feature and technical docs
- `specs/technical/` — generic technical and architecture guidance
- `specs/01-home-dashboard/` — Home Dashboard feature spec and subtopics
- `specs/02-soap-api-test/` — SOAP API Test feature spec and subtopics
- `specs/03-rest-api-test/` — REST API Test feature spec and subtopics
- `specs/04-file-management/` — File Management feature spec and subtopics
- `specs/05-test-suite/` — Test Suite feature spec and subtopics
- `specs/06-monitoring-health/` — Monitoring & Health feature spec and subtopics
- `specs/07-ad-viewer/` — AD Viewer feature spec
- `specs/08-settings/` — Settings feature spec

## Operating rules

- Read the relevant numbered spec before updating a feature.
- Keep changes narrow and aligned to the active feature being requested.
- Respect the current solution structure in `Features/`, `Components/`, and `WebApp/ServiceHubEnterprise.Web/`.
- Avoid out-of-scope refactors or broad edits unless the user explicitly asks for them.
