# OrbitHub.Dashboard

The **Dashboard** feature module provides the main landing page for the Service Hub Enterprise application, displaying aggregate metrics, recent activity, and health status widgets.

## Structure

```
Features/OrbitHub.Dashboard/
│
├── Core/                                    # Domain Layer
│   ├── Entities/                            # Domain Entities
│   │   ├── DashboardEntity.cs               # ServiceHealth, TestSuite entities
│   ├── Interfaces/                          # Repository contracts, grouped by domain
│   │   ├── Metrics/                         # IDashboardMetricsRepository
│   │   ├── Applications/                    # IDashboardApplicationsRepository (REST + SOAP)
│   │   ├── Assets/                          # IDashboardAssetsRepository (request files + WSDL)
│   │   ├── Users/                           # IDashboardUsersRepository (users + activity)
│   │   ├── TestSuites/                      # IDashboardTestSuitesRepository
│   │   ├── Executions/                      # IDashboardExecutionsRepository
│   │   └── Health/                          # IDashboardHealthRepository
│   └── Enums/                               # Feature-specific Enums
│       └── DashboardEnums.cs                # ServiceStatus, ChartType
│
├── Infrastructure/                          # Data Access Layer
│   ├── Data/                                # DbContext & Configurations (ready)
│   └── Repositories/                        # Grouped repository implementations
│       ├── Metrics/Applications/Assets/     # One repository per domain group
│       └── Users/TestSuites/Executions/Health/
│
├── Application/                             # Application Layer (Business Logic)
│   ├── DTOs/                                # Data Transfer Objects
│   │   ├── DashboardMetricsDto.cs           # Aggregate metrics DTO
│   │   ├── DashboardSnapshotDto.cs          # Full dashboard snapshot (all sections)
│   │   └── RecentActivityDto.cs             # Activity log entry DTO
│   ├── Services/                            # Application Services
│   │   ├── IDashboardService.cs             # Orchestrator contract (GetDashboardAsync)
│   │   ├── DashboardService.cs              # Parallel fan-out across the group services
│   │   ├── Metrics/Applications/Assets/     # One service per domain group
│   │   └── Users/TestSuites/Executions/Health/
│   ├── Validators/                          # Validation Logic (ready)
│   └── Mappings/                            # AutoMapper/Manual Mappings (ready)
│
├── UI/                                      # Presentation Layer
│   ├── Pages/                               # Page Components
│   │   ├── Dashboard.razor                  # Main dashboard page (@page "/")
│   │   └── Dashboard.razor.cs               # Code-behind
│   ├── Components/                          # Reusable UI Components
│   │   ├── DashboardMetrics.razor           # Stats cards row
│   │   ├── RecentActivity.razor             # Activity log feed
│   │   └── ChartWidgets.razor              # Bar / status chart widgets
│   └── Models/                              # UI ViewModels
│       └── DashboardViewModel.cs            # Dashboard, ServiceHealth, Activity view models
│
├── DependencyInjection/                     # Service Registration
│   └── ServiceCollectionExtensions.cs
│
├── wwwroot/                                 # Static Assets
│   └── css/
│       └── dashboard.css
│
├── OrbitHub.Dashboard.csproj
├── _Imports.razor
└── README.md
```

## Registration

The feature is registered in `Program.cs` via:

```csharp
.AddDashboardFeature()
```

This extension method is defined in `DependencyInjection/ServiceCollectionExtensions.cs` and registers all Dashboard services with the DI container.

## Dependencies

- **Microsoft.AspNetCore.Components.Web** — Blazor component model
- **Microsoft.AspNetCore.App** — ASP.NET Core framework reference
