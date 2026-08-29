# OrbitHub.SoapApplications

The **Soap Applications** feature module provides SOAP application management for the Service Hub Enterprise application, including application CRUD, request files, WSDL sync, templates, and execution history.

## Structure

```
Features/OrbitHub.SoapApplications/
│
├── Pages/                                    # Page Components
│   ├── SoapOverview.razor                    # Main Soap App page (@page "/soap/overview")
│   ├── Applications.razor                    # SOAP application management (@page "/soap/applications")
│   ├── RequestFiles.razor                    # SOAP request files (@page "/soap/request-files")
│   ├── WsdlSync.razor                        # WSDL sync workflow (@page "/soap/wsdl-sync")
│   ├── Templates.razor                       # Request file templates (@page "/soap/templates")
│   └── ExecuteHistory.razor                  # Execution history (@page "/soap/execute-history")
│
├── Components/                               # Soap App-specific components
│   ├── ApplicationsOverview.razor(.cs)       # Applications overview section card
│   ├── ExecutionsOverview.razor(.cs)         # Executions overview section card
│   ├── RequestFilesOverview.razor(.cs)       # Request Files overview section card
│   ├── TemplatesOverview.razor(.cs)          # Templates overview section card
│   └── WsdlSyncOverview.razor(.cs)           # WSDL Sync overview section card
│
├── Services/                                 # Soap App services (singleton stores)
│   ├── MockDbLoader.cs                       # Loads mock/seed data from mock_db/
│   ├── SoapAppStore.cs                       # SOAP apps + WSDL sync store
│   └── RequestExecutionStore.cs              # SOAP request-file execution history
│
├── Models/                                   # Soap App models (one class per file)
│   ├── SoapApiEntry.cs
│   ├── SoapApp.cs
│   ├── SoapRequestFile.cs
│   ├── WsdlSyncRecord.cs
│   ├── WsdlVersionEntry.cs
│   ├── WsdlTemplate.cs
│   ├── TemplateVariableDef.cs
│   ├── WsdlSyncHistoryPoint.cs
│   └── SoapExecution.cs
│
├── Core/                                     # Domain logic
│   ├── Entities/                             # Domain entities (ready)
│   └── Interfaces/                           # Domain service interfaces (ready)
│
├── Infrastructure/                           # Data access
│   ├── Data/                                 # Data access (ready)
│   └── Repositories/                         # Repository implementations (ready)
│
├── DependencyInjection/                      # Service Registration
│   └── ServiceCollectionExtensions.cs
│
├── wwwroot/                                  # Feature-specific static files
│   └── css/
│       └── soap-apps.css
│
├── OrbitHub.SoapApplications.csproj
├── _Imports.razor
└── README.md
```

## Registration

The feature is registered in `Program.cs` via:

```csharp
.AddSoapApplicationsFeature()
```

This extension method is defined in `DependencyInjection/ServiceCollectionExtensions.cs` and registers all Soap Applications services (as singletons) with the DI container.

## Dependencies

- **Microsoft.AspNetCore.Components.Web** — Blazor component model
- **Microsoft.AspNetCore.App** — ASP.NET Core framework reference
- **OrbitHub.Grid** — shared data-grid component
- **OrbitHub.Ui** — shared UI components (SectionCard, KpiTile, etc.)
