using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class WsdlSyncPageTests : BunitTestBase
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

    private void Setup(TempMockDb db)
    {
        var config = db.BuildConfiguration();
        var loader = new MockDbLoader(config);
        Services.AddSingleton(loader);
        Services.AddSingleton(new SoapAppStore(loader));
        Services.AddSingleton(new WsdlSyncStore(loader));
        Services.AddSingleton<IConfiguration>(config);
    }

    [Fact]
    public void RendersWithoutErrorAndShowsFirstApp()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Wsdl/wsdl-records.json",
                """[{"id":"rec-1","appId":"app-1","appName":"BillingService","sourceType":"url","sourceUrl":"https://soap.example.com/billing?wsdl","uploadedBy":"Priya Sharma","uploadedAt":"2024-06-01","status":"synced","versionCount":1}]"""),
            ("Wsdl/wsdl-versions.json",
                """[{"id":"ver-1","syncRecordId":"rec-1","versionNumber":1,"label":"v1","uploadedBy":"Priya Sharma","uploadedAt":"2024-06-01","status":"active"}]"""),
            ("Wsdl/wsdl-templates.json", "[]"),
            ("Wsdl/wsdl-sync-history.json", "[]"),
            ("Wsdl/wsdl-content-map.json", """{"previous":"prev.wsdl","changed":"changed.wsdl"}"""),
            ("Wsdl/prev.wsdl", "<wsdl>previous</wsdl>"),
            ("Wsdl/changed.wsdl", "<wsdl>changed</wsdl>"));
        Setup(db);

        var cut = Render<WsdlSync>();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("BillingService"), TimeSpan.FromSeconds(5));
        cut.Markup.Should().Contain("WSDL");
    }
}
