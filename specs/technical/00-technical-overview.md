# 00. Technical Overview

## Purpose

This application is structured as a multi-feature Blazor web application with a shared host and independently scoped feature modules. The host project at `WebApp/OrbitHub.Web` wires the feature registrations and provides the application shell, while each feature project under `Features/` exposes pages, components, services, and domain models for a specific operational domain.

## Current implementation structure

- `WebApp/OrbitHub.Web/Program.cs` registers the core application services and feature extension methods.
- Each feature project contains a dependency registration extension method, such as `AddDashboardFeature()` or `AddSoapApplicationsFeature()`.
- Most feature modules follow a similar boundary: pages, components, service/store classes, models, and dependency-injection registration.

## Key technology decisions

- ASP.NET Core + Blazor server-side interactive components are used for the UI.
- Data access uses **linq2db** v6.4.0 against a single **MS SQL Server** database (`OrbitTool`), with 11 focused `DataConnection` (linq2db DbContext) classes and a 112-class repository layer.
- All persistence is centralized in `Infrastructure/OrbitHub.Data/`; the database schema is defined in the `OrbitToolDatabase/` SSDT project.
- Shared UI conventions are provided by the component libraries under `Components/` and the feature-specific grid and UI helpers.
- Backend services are present in the folder `Backend`. Eache services has inidividual Test projects to test itself.

## Integration model

The system is designed around modular feature registration rather than a monolithic page model. Each feature owns its route namespace and persistence concerns, while the host remains responsible for app startup, routing, static files, and antiforgery setup.
ALos, each feature has individual service libraries defined in the `Backend`

## Operational expectation

The technical implementation should remain scoped to the active feature being changed, preserve the existing route contracts, and keep business behavior aligned with the page flows described in the feature specs that follow.
