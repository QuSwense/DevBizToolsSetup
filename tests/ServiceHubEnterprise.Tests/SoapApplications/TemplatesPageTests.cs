using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class TemplatesPageTests : BunitTestBase
{
    private const string TemplatesJson = """
[
  {
    "name": "Billing Request",
    "wsdl": "billing",
    "operation": "GetInvoice",
    "variables": 3,
    "status": "Published",
    "category": "BillingService",
    "description": "Billing request template",
    "tags": [],
    "endpointUrl": "https://soap.example.com/billing",
    "soapAction": "urn:GetInvoice",
    "xmlContent": "<soap:Envelope/>",
    "variableList": [],
    "created": "2024-01-01",
    "updated": "2024-06-01",
    "usage": 12
  },
  {
    "name": "Draft Sync",
    "wsdl": "sync",
    "operation": "Sync",
    "variables": 0,
    "status": "Draft",
    "category": "BillingService",
    "description": "",
    "tags": [],
    "endpointUrl": "",
    "soapAction": "",
    "xmlContent": "",
    "variableList": [],
    "created": "2024-02-01",
    "updated": "2024-02-01",
    "usage": 0
  }
]
""";

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

    private void Setup(TempMockDb db)
    {
        var config = db.BuildConfiguration();
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(config)
            .BuildServiceProvider();
        Services.AddSingleton(new SoapAppStore(sp));
        Services.AddSingleton<IConfiguration>(config);
    }

    [Fact]
    public void LoadsAndRendersTemplates()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/templates-page.json", TemplatesJson));
        Setup(db);

        var cut = Render<Templates>();
        // Templates.razor simulates a 1500ms load.
        cut.WaitForState(() => cut.FindAll(".skeleton-table").Count == 0, TimeSpan.FromSeconds(5));

        cut.Markup.Should().Contain("Billing Request");
        cut.Markup.Should().Contain("Draft Sync");
    }
}
