# 03. Blazor UI Pattern Specification

## UI conventions

The app uses Razor component pages and code-behind patterns for feature logic. The repository guidance calls for page-level logic to remain in `.razor.cs` files rather than inline `@code` blocks.

## Feature page structure

Each major feature is exposed through one or more Razor pages, for example:

- `Dashboard.razor` for the home screen
- `Applications.razor` and `RequestFiles.razor` for SOAP/REST management
- `Templates.razor`, `WsdlSync.razor`, and `ExecuteHistory.razor` for operational workflows

These pages are backed by strongly typed models, service/store injections, and incremental UI state handling.

## Shared component model

The solution includes a shared grid component and shared UI package used by the feature pages. This is meant to preserve consistent table rendering, summary cards, status badges, and layout patterns across the application.

## State and event handling

- UI actions should remain route-aware and feature-scoped.
- Async operations should keep progress updates and state changes explicit.
- Callback-driven navigation should not use unsafe direct component state mutation outside the owning page or store.

## Styling

The design system uses CSS variables for defaults and custom property-driven theming. Shared styles should remain central and avoid ad hoc hard-coded values in feature-level page code.

## Implementation guardrails

- Keep component markup declarative and avoid embedded logic that duplicates store behaviors.
- Preserve existing route names and navigation structure when extending pages.
- Do not add broad UI refactors without an explicit feature request.
