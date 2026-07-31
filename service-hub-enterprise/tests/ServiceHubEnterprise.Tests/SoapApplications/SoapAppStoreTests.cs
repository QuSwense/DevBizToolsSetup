using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Builders;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class SoapAppStoreTests : BunitTestBase
{
    private const string SoapAppsJson = """
[
  {
    "id": "app-1",
    "name": "BillingService",
    "baseUrl": "https://soap.example.com/billing",
    "wsdlPath": "?wsdl",
    "description": "Billing SOAP service",
    "status": "enabled",
    "createdBy": "Priya Sharma",
    "createdAt": "2024-01-15T00:00:00",
    "updatedBy": "Rahul Verma",
    "updatedAt": "2024-06-01T00:00:00",
    "apisCount": 1,
    "auth": { "type": "api-key", "keyName": "X-API-Key", "keyValue": "s3cret" },
    "apis": [ { "name": "GetInvoice", "description": "Gets an invoice" } ]
  },
  {
    "id": "app-2",
    "name": "InventorySync",
    "baseUrl": "https://soap.example.com/inventory",
    "wsdlPath": "?wsdl",
    "description": "Inventory sync service",
    "status": "disabled",
    "createdBy": "Rahul Verma",
    "createdAt": "2024-02-01T00:00:00",
    "updatedBy": null,
    "updatedAt": null,
    "apisCount": 0,
    "auth": { "type": "ntlm", "username": "svc", "password": "pw", "domain": "CORP" },
    "apis": []
  }
]
""";

    [Fact]
    public void LoadsAppsAndDeserializesStatusAndAuth()
    {
        using var db = MockDbFixture.CreateTempMockDb(("soap-apps.json", SoapAppsJson));
        var store = new SoapAppStore(new MockDbLoader(db.BuildConfiguration()));

        store.Apps.Should().HaveCount(2);

        var billing = store.Apps[0];
        billing.Id.Should().Be("app-1");
        billing.Name.Should().Be("BillingService");
        billing.Status.Should().Be(AppStatus.Enabled);
        billing.Auth.Type.Should().Be(AuthType.ApiKey);
        billing.Auth.KeyName.Should().Be("X-API-Key");
        billing.Auth.KeyValue.Should().Be("s3cret");
        billing.Apis.Should().ContainSingle(a => a.Name == "GetInvoice");

        var inventory = store.Apps[1];
        inventory.Status.Should().Be(AppStatus.Disabled);
        inventory.Auth.Type.Should().Be(AuthType.Ntlm);
        inventory.Auth.Domain.Should().Be("CORP");
    }

    [Fact]
    public void UpdateAppsReplacesApps()
    {
        using var db = MockDbFixture.CreateTempMockDb(("soap-apps.json", "[]"));
        var store = new SoapAppStore(new MockDbLoader(db.BuildConfiguration()));

        store.UpdateApps(new[] { TestData.SoapApp(id: "x", name: "NewApp") });

        store.Apps.Should().ContainSingle(a => a.Id == "x" && a.Name == "NewApp");
    }
}
