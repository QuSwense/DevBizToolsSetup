# 00. Technical Overview

## Purpose

This application is structured as a multi-feature Blazor web application with a shared host and independently scoped feature modules. The host project at `WebApp/ServiceHubEnterprise.Web` wires the feature registrations and provides the application shell, while each feature project under `Features/` exposes pages, components, services, and domain models for a specific operational domain.

## Current implementation structure

- `WebApp/ServiceHubEnterprise.Web/Program.cs` registers the core application services and feature extension methods.
- Each feature project contains a dependency registration extension method, such as `AddDashboardFeature()` or `AddSoapApplicationsFeature()`.
- Most feature modules follow a similar boundary: pages, components, service/store classes, models, and dependency-injection registration.

## Key technology decisions

- ASP.NET Core + Blazor server-side interactive components are used for the UI.
- Feature data access is split across focused `DbContext` registrations for dashboard, SOAP, REST, file management, and WSDL content.
- Mock data is centralized in the solution `mock_db/` folder and is loaded through the feature-specific singleton store services.
- Shared UI conventions are provided by the component libraries under `Components/` and the feature-specific grid and UI helpers.

## Integration model

The system is designed around modular feature registration rather than a monolithic page model. Each feature owns its route namespace and persistence concerns, while the host remains responsible for app startup, routing, static files, and antiforgery setup.

## Operational expectation

The technical implementation should remain scoped to the active feature being changed, preserve the existing route contracts, and keep business behavior aligned with the page flows described in the feature specs that follow.
