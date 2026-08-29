# 01. Home Dashboard

## Purpose

The Home Dashboard serves as the application landing experience. It provides a high-level operational and quality assurance overview that is easily digestible for both technical staff and business executives.

## Primary routes

- `/` — Root landing page for the dashboard

## Core business outcomes

- **Executive & Operational Visibility:** Provides real-time visibility into platform activity, service availability, and automated test execution across SOAP and REST applications.
- **System Health & Reliability Monitoring:** Enables early detection of service downtime, degraded performance, and failing test suites to minimize operational disruptions.
- **Workflow Efficiency & Fast Navigation:** Surfaces recent cross-system activities and provides direct access to primary management workflows via quick actions.
- **Data-Driven Quality Assurance:** Tracks historical test execution trends, request/response metrics, and pass/fail ratios to evaluate release quality across customizable timeframes.

## View summary

Displays high-level KPI tiles in a responsive grid layout. Tiles marked with **[Card Filter]** contain an independent Date Range Filter in their header to scope that card's metrics independently.

- **Users Card:**
  - Total users registered in the platform
  - Active Users (DAU / MAU: Users who logged in or performed an action within the last 24 hours or 30 days)
- **Test Suites Card:** **[Card Filter]**
  - Count of all registered test suites
  - Total execution counts
  - Pass / Fail percentage breakdown (2D Pie Chart)
- **Service Health Card:**
  - Total number of monitored services
  - Available vs. Unavailable service status breakdown (2D Pie Chart)
- **SOAP Application Card:** **[Card Filter]**
  - Total number of SOAP applications
  - Count of available request files
  - Total execution count
  - Total response count
- **REST Application Card:** **[Card Filter]**
  - Total number of REST applications
  - Count of available request files
  - Total execution count
  - Total response count
- **Recent Activities Card:**
  - Chronological activity log showing recent system events and user actions across the platform
- **Quick Actions:**
  - Direct shortcut links to primary workflows:
    - *Create New Test Suite*
    - *Register Application (SOAP/REST)*
    - *View Service Health Logs*
    - *User Management*

## Current implementation anchors

- `Features/OrbitHub.Dashboard/UI/Pages/Dashboard.razor`
- `Features/OrbitHub.Dashboard/DependencyInjection/ServiceCollectionExtensions.cs`
- `Features/OrbitHub.Dashboard/README.md`

## Expected feature behavior

The dashboard must present service health metrics, execution summaries, and recent activity logs in a clean, responsive layout. Cards containing an independent date picker must dynamically refetch their respective data without triggering a full-page reload or affecting adjacent dashboard cards.