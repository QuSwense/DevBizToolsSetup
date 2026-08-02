using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class SoapOverviewPageTests : BunitTestBase
{
    private const string AppsJson = """
[
  {
    "id": "app-1",
    "name": "BillingService",
    "baseUrl": "https://soap.example.com/billing",
    "wsdlPath": "?wsdl",
    "description": "Billing",
    "status": "enabled",
    "createdBy": "Priya Sharma",
    "createdAt": "2024-01-15T00:00:00",
    "updatedBy": "Rahul Verma",
    "updatedAt": "2024-06-01T00:00:00",
    "apisCount": 1,
    "auth": { "type": "none" },
    "apis": [ { "name": "GetInvoice", "description": "" } ]
  }
]
""";

    private const string FilesJson = """
[
  { "fileName": "GetInvoice.xml", "appName": "BillingService", "apiPath": "GetInvoice", "verb": "GET", "description": "", "status": "active", "createdBy": "Priya Sharma", "createdAt": "2024-06-01T10:00:00", "updatedBy": "Rahul Verma", "updatedAt": "2024-06-01T10:00:00" }
]
""";

    private const string ExecutionsJson = """
[
  { "id": "ex-1", "appName": "BillingService", "appType": "soap", "fileName": "GetInvoice.xml", "status": "success", "executedAt": "2024-06-01 10:00:00", "durationMs": 100, "triggeredBy": "Priya Sharma" }
]
""";

    private void Setup(TempMockDb db)
    {
        var config = db.BuildConfiguration();
        var loader = new MockDbLoader(config);
        Services.AddSingleton(loader);
        Services.AddSingleton(new SoapAppStore(loader));
        Services.AddSingleton(new WsdlSyncStore(loader));
        Services.AddSingleton(new RequestExecutionStore(loader));
        Services.AddSingleton<IConfiguration>(config);
    }

    [Fact]
    public void RendersAllFiveOverviewCards()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson),
            ("Soap/Request/request-executions.json", ExecutionsJson),
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-versions.json", "[]"),
            ("Wsdl/wsdl-templates.json", "[]"),
            ("Wsdl/wsdl-sync-history.json", "[]"));
        Setup(db);

        var cut = Render<SoapOverview>();
        cut.WaitForState(() => cut.FindAll(".section-card").Count == 5, TimeSpan.FromSeconds(5));

        var titles = cut.FindAll(".card-title").Select(t => t.TextContent.Trim());
        titles.Should().Contain("Applications");
        titles.Should().Contain("Request Files");
        titles.Should().Contain("Executions");
        titles.Should().Contain("WSDL Sync");
        titles.Should().Contain("Templates");
    }
}
