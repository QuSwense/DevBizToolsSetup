# 06. Monitoring & Health

## Purpose

The Monitoring & Health feature provides the operational visibility layer for the platform, focusing on service health and operational monitoring across system components.

## Primary routes

- `/health`

## Core business outcomes

- Surface health and availability information.
- Provide a monitoring dashboard for the platform.
- Support rapid operational awareness and response.

## Current implementation anchors

- `Features/OrbitHub.MonitoringHealth/Pages/HealthDashboard.razor`
- `Features/OrbitHub.MonitoringHealth/DependencyInjection.cs`

## Integration

Health monitoring is application-agnostic and provides status information for all platform components including SOAP execution engines, REST endpoints, database connectivity, and authentication services.
