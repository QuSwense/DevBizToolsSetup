using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class ApplicationsPageTests : BunitTestBase
{
    private const string AppsJson = """
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
  },
  {
    "id": "app-3",
    "name": "OrdersApi",
    "baseUrl": "https://soap.example.com/orders",
    "wsdlPath": "?wsdl",
    "description": "Orders service",
    "status": "enabled",
    "createdBy": "Priya Sharma",
    "createdAt": "2024-03-01T00:00:00",
    "updatedBy": "Priya Sharma",
    "updatedAt": "2024-05-01T00:00:00",
    "apisCount": 2,
    "auth": { "type": "basic", "username": "svc", "password": "pw" },
    "apis": [ { "name": "GetOrders", "description": "" }, { "name": "CreateOrder", "description": "" } ]
  }
]
""";

    private SoapAppStore Setup(TempMockDb db)
    {
        var config = db.BuildConfiguration();
        var loader = new MockDbLoader(config);
        var store = new SoapAppStore(loader);
        Services.AddSingleton(loader);
        Services.AddSingleton(store);
        Services.AddSingleton(new SoapTestCaseStore(loader));
        Services.AddSingleton(new SoapExecutionStore(loader));
        Services.AddSingleton(new WsdlSyncStore(loader));
        Services.AddSingleton<IConfiguration>(config);
        return store;
    }

    private static IRenderedComponent<Applications> RenderAndWait(ApplicationsPageTests owner)
    {
        var cut = owner.Render<Applications>();
        // Applications.razor simulates a 1000ms load; wait for the skeleton to clear.
        cut.WaitForState(() => cut.FindAll(".skeleton-table").Count == 0, TimeSpan.FromSeconds(5));
        return cut;
    }

    [Fact]
    public void RendersLoadingSkeletonInitially()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = Render<Applications>();

        cut.Find(".skeleton-table").Should().NotBeNull();
    }

    [Fact]
    public void LoadsAndRendersApplicationsInGrid()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = RenderAndWait(this);

        cut.FindAll("tbody tr").Should().HaveCount(3);
        cut.Markup.Should().Contain("BillingService");
        cut.FindAll(".meta-pill").Any(p => p.TextContent.Trim() == "3 records").Should().BeTrue();
    }

    [Fact]
    public void AddModalShowsValidationErrorsForInvalidInput()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find("button[aria-label=\"Add Application\"]").Click();
        cut.WaitForAssertion(() => cut.Find("input[placeholder=\"Enter application name...\"]").Should().NotBeNull(), TimeSpan.FromSeconds(3));

        cut.Find("input[placeholder=\"Enter application name...\"]").Input("Bad@Name!");
        cut.Find("input[placeholder=\"https://soap.example.com/Service\"]").Input("not-a-url");
        cut.Find(".modal-footer-dg button.btn-sh-primary").Click();

        cut.Find(".alert-validation").TextContent
            .Should().Contain("App name may only contain")
            .And.Contain("Base URL must be a valid");
    }

    [Fact]
    public void AddApplicationPersistsToStore()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var store = Setup(db);

        var cut = RenderAndWait(this);
        cut.Find("button[aria-label=\"Add Application\"]").Click();
        cut.WaitForAssertion(() => cut.Find("input[placeholder=\"Enter application name...\"]").Should().NotBeNull(), TimeSpan.FromSeconds(3));

        cut.Find("input[placeholder=\"Enter application name...\"]").Input("NewBilling");
        cut.Find("input[placeholder=\"https://soap.example.com/Service\"]").Input("https://soap.example.com/newbilling");
        cut.Find("input[placeholder=\"?wsdl\"]").Input("?wsdl");
        cut.FindAll("button").First(b => b.TextContent.Contains("Add API")).Click();
        cut.Find("input[placeholder=\"API name...\"]").Input("GetBill");
        cut.Find(".modal-footer-dg button.btn-sh-primary").Click();

        store.Apps.Should().HaveCount(4);
        store.Apps.Last().Name.Should().Be("NewBilling");
        store.Apps.Last().Auth.Type.Should().Be(AuthType.Basic);
        cut.FindAll(".modal-content-dg").Should().BeEmpty();
    }

    [Fact]
    public void EditDialogPrefillsValues()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.FindAll(".ia-btn.ia-normal")[0].Click();
        cut.WaitForAssertion(() => cut.Find(".modal-content-dg").Should().NotBeNull(), TimeSpan.FromSeconds(3));

        cut.Find(".modal-header-dg h3").TextContent.Should().Be("Edit SOAP Application");
        cut.Find("input[placeholder=\"Enter application name...\"]").GetAttribute("value").Should().Be("BillingService");
        cut.Find("input[placeholder=\"https://soap.example.com/Service\"]").GetAttribute("value").Should().Be("https://soap.example.com/billing");
    }

    [Fact]
    public async Task ContextMenuProviderReturnsMenuItems()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = RenderAndWait(this);
        var grid = cut.FindComponent<ServiceHubGrid<SoapApp>>();

        var items = await cut.InvokeAsync(() => grid.Instance.GetContextMenuItems("app-1"));

        items.Select(i => i.Label).Should().Contain("View Details", "Edit", "Delete");
        items.First(i => i.Action == "delete").Danger.Should().BeTrue();
    }

    [Fact]
    public async Task ContextMenuToggleUpdatesStatusAndShowsToast()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var store = Setup(db);

        var cut = RenderAndWait(this);
        var grid = cut.FindComponent<ServiceHubGrid<SoapApp>>();

        await cut.InvokeAsync(() => grid.Instance.HandleContextMenuAction("app-1", "toggle"));

        store.Apps.First(a => a.Id == "app-1").Status.Should().Be(AppStatus.Disabled);
        cut.Find(".sh-toast").TextContent.Should().Contain("disabled");
    }

    [Fact]
    public void FilterModalFiltersByName()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find(".filter-btn").Click();
        cut.WaitForAssertion(() => cut.Find("input[placeholder=\"Filter by name...\"]").Should().NotBeNull(), TimeSpan.FromSeconds(3));
        cut.Find("input[placeholder=\"Filter by name...\"]").Input("Billing");
        cut.FindAll("button").First(b => b.TextContent.Contains("Apply Filters")).Click();

        cut.FindAll("tbody tr").Should().HaveCount(1);
        cut.Markup.Should().Contain("BillingService");
        cut.Markup.Should().NotContain("InventorySync");
    }
}
