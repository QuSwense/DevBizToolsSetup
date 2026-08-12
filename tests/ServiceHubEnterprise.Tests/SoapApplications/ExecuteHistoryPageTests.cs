using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Pages;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class ExecuteHistoryPageTests : BunitTestBase
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
    "apisCount": 1,
    "auth": { "type": "none" },
    "apis": [ { "name": "GetInvoice", "description": "" } ]
  }
]
""";

    private const string FilesJson = """
[
  { "fileName": "GetInvoice.xml", "appName": "BillingService", "apiPath": "GetInvoice", "verb": "GET", "description": "", "status": "active", "createdBy": "Priya Sharma", "createdAt": "2024-05-01T10:00:00", "updatedBy": null, "updatedAt": null }
]
""";

    private const string ExecutionsJson = """
[
  {
    "id": "exg-1",
    "startedAt": "2026-08-02 10:00:00",
    "finishedAt": "2026-08-02 10:00:03",
    "triggeredBy": "Priya Sharma",
    "status": "completed",
    "durationMs": 3000,
    "files": [
      {
        "fileName": "GetInvoice.xml",
        "appName": "BillingService",
        "operation": "GetInvoice",
        "status": "success",
        "stage": "Complete",
        "stagesCompleted": 7,
        "stagesTotal": 7,
        "durationMs": 3000,
        "requestContent": "<soap:Envelope><soap:Body><GetInvoice /></soap:Body></soap:Envelope>",
        "responseContent": "<soap:Envelope><soap:Body><status>Success</status></soap:Body></soap:Envelope>",
        "responseMimeType": "text/xml",
        "parsedFields": [ { "name": "status", "source": "response", "path": "//status", "value": "Success", "isEmbedded": false } ],
        "extractions": [],
        "logs": [ { "id": "log-1", "timestamp": "2026-08-02 10:00:00", "type": "info", "message": "Execution completed" } ]
      }
    ]
  },
  {
    "id": "exg-2",
    "startedAt": "2026-08-02 11:00:00",
    "finishedAt": "2026-08-02 11:00:03",
    "triggeredBy": "Rahul Verma",
    "status": "failed",
    "durationMs": 3000,
    "files": [
      {
        "fileName": "Other.xml",
        "appName": "BillingService",
        "operation": "GetInvoice",
        "status": "failed",
        "stage": "Complete",
        "stagesCompleted": 7,
        "stagesTotal": 7,
        "durationMs": 3000,
        "requestContent": "<req/>",
        "responseContent": "",
        "responseMimeType": "text/xml",
        "parsedFields": [],
        "extractions": [],
        "logs": [ { "id": "log-2", "timestamp": "2026-08-02 11:00:00", "type": "error", "message": "Simulated failure" } ]
      }
    ]
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
        Services.AddSingleton(new SoapTestCaseStore(sp));
        Services.AddSingleton(new SoapExecutionStore(sp));
        Services.AddSingleton<IConfiguration>(config);
    }

    private static TempMockDb CreateDb()
        => MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson),
            ("Soap/soap-executions.json", ExecutionsJson));

    private static IRenderedComponent<ExecuteHistory> RenderAndWait(ExecuteHistoryPageTests owner)
    {
        var cut = owner.Render<ExecuteHistory>();
        cut.WaitForState(() => cut.FindAll(".spinner-border").Count == 0, TimeSpan.FromSeconds(5));
        return cut;
    }

    [Fact]
    public void RendersExecutionGroups()
    {
        using var db = CreateDb();
        Setup(db);

        var cut = RenderAndWait(this);

        cut.Markup.Should().Contain("exg-1");
        cut.Markup.Should().Contain("exg-2");
        cut.Markup.Should().Contain("Completed");
        cut.Markup.Should().Contain("Failed");
    }

    [Fact]
    public void FileQueryFilter_ShowsOnlyMatchingGroups()
    {
        using var db = CreateDb();
        Setup(db);
        AddFakeNavigationManager().NavigateTo("/soap/execute-history?file=GetInvoice.xml");

        var cut = RenderAndWait(this);

        cut.Markup.Should().Contain("exg-1");
        cut.Markup.Should().NotContain("exg-2");
    }

    [Fact]
    public void GroupQuery_PreselectsGroup_AndRendersFileDetails()
    {
        using var db = CreateDb();
        Setup(db);
        AddFakeNavigationManager().NavigateTo("/soap/execute-history?group=exg-1");

        var cut = RenderAndWait(this);

        // Details component tabs + content render for the preselected file.
        cut.Markup.Should().Contain("Request");
        cut.Markup.Should().Contain("Response");
        cut.Markup.Should().Contain("Parsed Fields");
        cut.Markup.Should().Contain("Logs");
        cut.Markup.Should().Contain("GetInvoice.xml");
    }

    [Fact]
    public void NoExecutions_ShowsEmptyState()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Soap/soap-apps.json", AppsJson),
            ("Soap/Request/request-files.json", FilesJson),
            ("Soap/soap-executions.json", "[]"));
        Setup(db);

        var cut = RenderAndWait(this);

        cut.Markup.Should().Contain("No executions yet");
    }
}
