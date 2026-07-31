using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class RequestFilesPageTests : BunitTestBase
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
    "apis": [ { "name": "GetInvoice", "description": "Gets an invoice" } ]
  }
]
""";

    private const string FilesJson = """
[
  { "fileName": "GetInvoice.xml", "appName": "BillingService", "apiPath": "GetInvoice", "verb": "GET", "description": "", "status": "active", "createdBy": "Priya Sharma", "createdAt": "2024-05-01T10:00:00", "updatedBy": "Rahul Verma", "updatedAt": "2024-06-01T10:00:00" },
  { "fileName": "CreateInvoice.xml", "appName": "BillingService", "apiPath": "CreateInvoice", "verb": "POST", "description": "", "status": "active", "createdBy": "Priya Sharma", "createdAt": "2024-05-02T10:00:00", "updatedBy": null, "updatedAt": null },
  { "fileName": "ArchiveInvoice.xml", "appName": "BillingService", "apiPath": "ArchiveInvoice", "verb": "POST", "description": "", "status": "inactive", "createdBy": "Rahul Verma", "createdAt": "2024-04-01T10:00:00", "updatedBy": "Rahul Verma", "updatedAt": "2024-04-10T10:00:00" }
]
""";

    private void Setup(TempMockDb db)
    {
        var config = db.BuildConfiguration(requestFilesDelayMs: 0);
        var loader = new MockDbLoader(config);
        Services.AddSingleton(loader);
        Services.AddSingleton(new SoapAppStore(loader));
        Services.AddSingleton<IConfiguration>(config);
    }

    private static IRenderedComponent<RequestFiles> RenderAndWait(RequestFilesPageTests owner)
    {
        var cut = owner.Render<RequestFiles>();
        cut.WaitForState(() => cut.FindAll(".skeleton-table").Count == 0, TimeSpan.FromSeconds(5));
        return cut;
    }

    [Fact]
    public void LoadsAndRendersRequestFiles()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("soap-apps.json", AppsJson),
            ("request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);

        cut.FindAll("tbody tr").Should().HaveCount(3);
        cut.Markup.Should().Contain("GetInvoice.xml");
    }

    [Fact]
    public void UploadModalShowsValidationErrors()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("soap-apps.json", AppsJson),
            ("request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find("button[aria-label=\"Upload File\"]").Click();
        cut.WaitForAssertion(() => cut.Find(".modal-footer-dg button.btn-sh-primary").Should().NotBeNull(), TimeSpan.FromSeconds(3));

        // No app/operation/file selected → validation errors.
        cut.Find(".modal-footer-dg button.btn-sh-primary").Click();

        cut.WaitForAssertion(() => cut.Find(".alert-validation").TextContent
            .Should().Contain("Application is required.")
            .And.Contain("Operation is required.")
            .And.Contain("At least one file with a file name is required."));
    }

    [Fact]
    public void SearchFiltersRows()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("soap-apps.json", AppsJson),
            ("request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find(".search-box input").Input("GetInvoice");

        cut.WaitForAssertion(() => cut.FindAll("tbody tr").Should().HaveCount(1));
        cut.Markup.Should().Contain("GetInvoice.xml");
        cut.Markup.Should().NotContain("CreateInvoice.xml");
    }
}
