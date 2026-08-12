using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.SoapApplications.Services.Execution;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class SimulatedSoapExecutionEngineTests
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
  },
  {
    "id": "app-2",
    "name": "DisabledApp",
    "baseUrl": "https://soap.example.com/disabled",
    "wsdlPath": "?wsdl",
    "description": "Disabled",
    "status": "disabled",
    "createdBy": "Priya Sharma",
    "createdAt": "2024-01-15T00:00:00",
    "apisCount": 1,
    "auth": { "type": "none" },
    "apis": [ { "name": "DoThing", "description": "" } ]
  }
]
""";

    private (SimulatedSoapExecutionEngine Engine, SoapTestCaseStore TcStore) Setup(
        TempMockDb db, string? tcJson = null)
    {
        if (tcJson is not null)
        {
            db.WriteFile("Soap/soap-test-cases.json", tcJson);
        }

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["MockDb:Path"] = db.Path,
                ["Users:CurrentUser"] = "Priya Sharma",
                ["MockDb:ExecutionStageDelayMs"] = "0"
            })
            .Build();

        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(config)
            .BuildServiceProvider();
        var appStore = new SoapAppStore(sp);
        var tcStore = new SoapTestCaseStore(sp);
        var engine = new SimulatedSoapExecutionEngine(config, appStore, tcStore);
        return (engine, tcStore);
    }

    private static SoapRequestFile File(string name, string app = "BillingService", string operation = "GetInvoice")
        => new(name, app, operation, "GET", "", "active", "Priya Sharma", DateTime.Now, null, null);

    [Fact]
    public async Task RunAsync_CompletesFiles_AsSuccess()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db);

        var group = engine.CreateGroup([File("GetInvoice.xml")], "Priya Sharma");

        group.Id.Should().StartWith("exg-");
        group.Status.Should().Be("running");

        await engine.RunAsync(group);

        group.Files.Should().HaveCount(1);
        group.Files[0].Status.Should().Be("success");
        group.Files[0].Stage.Should().Be(ExecutionStage.Complete);
        group.Files[0].StagesCompleted.Should().Be(group.Files[0].StagesTotal);
        group.Files[0].RequestContent.Should().Contain("GetInvoice");
        group.Files[0].ResponseContent.Should().Contain("<status>Success</status>");
        group.Files[0].ParsedFields.Should().NotBeEmpty();
        group.Files[0].Logs.Should().NotBeEmpty();
        group.Status.Should().Be("completed");
    }

    [Fact]
    public async Task CreateGroup_AssignsUniqueId_EvenForSingleFile()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db);

        var g1 = engine.CreateGroup([File("a.xml")], "Priya Sharma");
        var g2 = engine.CreateGroup([File("a.xml")], "Priya Sharma");

        g1.Id.Should().NotBe(g2.Id);
    }

    [Fact]
    public async Task RunAsync_BlocksDisabledApplication()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db);

        var group = engine.CreateGroup([File("DoThing.xml", "DisabledApp", "DoThing")], "Priya Sharma");
        await engine.RunAsync(group);

        group.Files[0].Status.Should().Be("failed");
        group.Files[0].Logs.Should().Contain(l => l.Type == "error");
        group.Status.Should().Be("failed");
    }

    [Fact]
    public async Task RunAsync_SimulatedFailure_WhenFileNameContainsFail()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db);

        var group = engine.CreateGroup([File("check_failed.xml")], "Priya Sharma");
        await engine.RunAsync(group);

        group.Files[0].Status.Should().Be("failed");
        group.Status.Should().Be("failed");
    }

    [Fact]
    public async Task RunAsync_ExtractsParsedEmbeddedField_WithDecodedPreview()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db);

        var group = engine.CreateGroup([File("GetInvoice.xml")], "Priya Sharma");
        await engine.RunAsync(group);

        var embedded = group.Files[0].ParsedFields.FirstOrDefault(f => f.IsEmbedded);
        embedded.Should().NotBeNull();
        embedded!.DecodedPreview.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task RunAsync_RunsAttachedTestCases_AndReportsPassFail()
    {
        const string tcJson = """
[
  {
    "id": "tc-1",
    "name": "Validate status",
    "description": "",
    "appName": "BillingService",
    "fileName": "GetInvoice.xml",
    "enabled": true,
    "createdBy": "Priya Sharma",
    "createdAt": "2026-08-01 00:00:00",
    "extractors": [
      { "id": "ex-1", "name": "status", "source": "response", "type": "xpath", "path": "//status", "expectedValue": "Success" }
    ]
  }
]
""";
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db, tcJson);

        var group = engine.CreateGroup([File("GetInvoice.xml")], "Priya Sharma");
        await engine.RunAsync(group);

        var ex = group.Files[0].Extractions.Should().ContainSingle().And.Subject.Single();
        ex.Passed.Should().BeTrue($"Value='{ex.Value}', Expected='{ex.Expected}', Path='{ex.Path}', Type='{ex.Type}', hasExpected={ex.HasExpected}");
        ex.Value.Should().Be("Success");
        ex.HasExpected.Should().BeTrue();
    }

    [Fact]
    public async Task RunAsync_ReportsFailedAssertion_WhenExpectedValueMismatches()
    {
        const string tcJson = """
[
  {
    "id": "tc-2",
    "name": "Validate status",
    "description": "",
    "appName": "BillingService",
    "fileName": "GetInvoice.xml",
    "enabled": true,
    "createdBy": "Priya Sharma",
    "createdAt": "2026-08-01 00:00:00",
    "extractors": [
      { "id": "ex-2", "name": "status", "source": "response", "type": "xpath", "path": "//status", "expectedValue": "Failure" }
    ]
  }
]
""";
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-apps.json", AppsJson));
        var (engine, _) = Setup(db, tcJson);

        var group = engine.CreateGroup([File("GetInvoice.xml")], "Priya Sharma");
        await engine.RunAsync(group);

        var ex = group.Files[0].Extractions.Should().ContainSingle().And.Subject.Single();
        ex.Passed.Should().BeFalse();
        ex.Value.Should().Be("Success");
    }
}
