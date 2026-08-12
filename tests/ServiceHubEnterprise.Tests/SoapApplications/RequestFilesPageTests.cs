using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.SoapApplications.Services.Execution;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

/// <summary>
/// Deterministic engine double that completes synchronously, so the page-level
/// execute test verifies the wiring (group created → persisted → navigated)
/// without depending on bUnit's async event handling. The real engine's stage
/// logic is covered by <see cref="SimulatedSoapExecutionEngineTests"/>.
/// </summary>
internal sealed class StubExecutionEngine : IExecutionEngine
{
    public SoapExecutionGroup CreateGroup(IReadOnlyList<SoapRequestFile> files, string triggeredBy)
    {
        var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        return new SoapExecutionGroup
        {
            Id = "exg-stub",
            StartedAt = now,
            FinishedAt = now,
            TriggeredBy = triggeredBy,
            Status = "completed",
            Files = files.Select(f => new SoapExecutionFile
            {
                FileName = f.FileName,
                AppName = f.AppName,
                Operation = f.ApiPath,
                Status = "success",
                Stage = ExecutionStage.Complete,
                StagesCompleted = 7,
                StagesTotal = 7
            }).ToList()
        };
    }

    public Task RunAsync(
        SoapExecutionGroup group,
        IProgress<SoapExecutionGroup>? progress = null,
        CancellationToken cancellationToken = default)
    {
        progress?.Report(group);
        return Task.CompletedTask;
    }
}

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

    private SoapExecutionStore Setup(TempMockDb db)
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["MockDb:Path"] = db.Path,
                ["Users:CurrentUser"] = "Priya Sharma",
                ["MockDb:RequestFilesDelayMs"] = "0",
                ["MockDb:ExecutionStageDelayMs"] = "0"
            })
            .Build();
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(config)
            .BuildServiceProvider();
        var appStore = new SoapAppStore(sp);
        var testCaseStore = new SoapTestCaseStore(sp);
        var executionStore = new SoapExecutionStore(sp);
        Services.AddSingleton(appStore);
        Services.AddSingleton(testCaseStore);
        Services.AddSingleton(executionStore);
        Services.AddSingleton<IExecutionEngine>(new SimulatedSoapExecutionEngine(config, appStore, testCaseStore));
        Services.AddSingleton<IConfiguration>(config);
        return executionStore;
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
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);

        cut.FindAll("tbody tr").Should().HaveCount(3);
        cut.Markup.Should().Contain("GetInvoice.xml");
    }

    [Fact]
    public void UploadModalShowsValidationErrors()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson));
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
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find(".search-box input").Input("GetInvoice");

        cut.WaitForAssertion(() => cut.FindAll("tbody tr").Should().HaveCount(1));
        cut.Markup.Should().Contain("GetInvoice.xml");
        cut.Markup.Should().NotContain("CreateInvoice.xml");
    }

    [Fact]
    public void ExecuteRowAction_CreatesAndPersistsExecutionGroup()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson));
        var executionStore = Setup(db);
        // Override the engine with a synchronous stub for a deterministic test.
        Services.AddSingleton<IExecutionEngine>(new StubExecutionEngine());

        var cut = RenderAndWait(this);
        cut.FindAll("button[aria-label=\"Execute\"]").First().Click();

        cut.WaitForAssertion(() =>
        {
            executionStore.Groups.Should().ContainSingle();
            var group = executionStore.Groups[0];
            group.Id.Should().Be("exg-stub");
            group.Files.Should().ContainSingle(f => f.FileName == "GetInvoice.xml");
            group.Files[0].Status.Should().Be("success");
            group.Status.Should().Be("completed");
        }, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public void UploadModal_RejectsDuplicateFileNameForApplication()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson));
        Setup(db);

        var cut = RenderAndWait(this);
        cut.Find("button[aria-label=\"Upload File\"]").Click();
        cut.WaitForAssertion(() => cut.Find(".modal-footer-dg button.btn-sh-primary").Should().NotBeNull(), TimeSpan.FromSeconds(3));

        cut.FindAll(".modal-content-dg select")[0].Input("BillingService");
        cut.FindAll(".modal-content-dg select")[1].Input("GetInvoice");
        cut.FindAll("button").First(b => b.TextContent.Contains("Add File")).Click();
        cut.Find("input[placeholder=\"File name (e.g. invoice_create.xml)\"]").Input("GetInvoice.xml");
        cut.FindAll(".modal-footer-dg button").Last().Click();

        cut.WaitForAssertion(() => cut.Find(".alert-validation").TextContent
            .Should().Contain("File(s) already exist for this application"), TimeSpan.FromSeconds(3));
    }
}
