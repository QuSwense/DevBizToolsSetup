using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class SoapTestCaseStoreTests
{
    private static SoapTestCase TestCase(string id, string name, bool enabled = true) => new()
    {
        Id = id,
        Name = name,
        Description = "",
        AppName = "BillingService",
        FileName = "GetInvoice.xml",
        Enabled = enabled,
        CreatedBy = "Priya Sharma",
        CreatedAt = "2026-08-01 00:00:00",
        Extractors =
        [
            new SoapExtractor { Id = "ex-1", Name = "status", Source = "response", Type = "xpath", Path = "//status", ExpectedValue = "Success" }
        ]
    };

    [Fact]
    public async Task Add_GetForFile_Update_Delete_RoundTrip()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-test-cases.json", "[]"));
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        var store = new SoapTestCaseStore(sp);

        await store.AddTestCaseAsync(TestCase("tc-1", "Validate status"));
        store.GetEnabledForFile("BillingService", "GetInvoice.xml").Should().ContainSingle();

        // Persisted to JSON → a fresh store sees it.
        var reloaded = new SoapTestCaseStore(sp);
        reloaded.GetForFile("BillingService", "GetInvoice.xml").Should().ContainSingle(t => t.Id == "tc-1");

        // Update
        var tc = reloaded.GetTestCase("tc-1")!;
        tc.Enabled = false;
        await reloaded.UpdateTestCaseAsync(tc);
        reloaded.GetEnabledForFile("BillingService", "GetInvoice.xml").Should().BeEmpty();

        // Delete
        await reloaded.DeleteTestCaseAsync("tc-1");
        reloaded.TestCases.Should().BeEmpty();
    }

    [Fact]
    public async Task GetEnabledForFile_ExcludesDisabledAndOtherFiles()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-test-cases.json", "[]"));
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        var store = new SoapTestCaseStore(sp);

        await store.AddTestCaseAsync(TestCase("tc-1", "Enabled", enabled: true));
        await store.AddTestCaseAsync(TestCase("tc-2", "Disabled", enabled: false));

        var otherFile = TestCase("tc-3", "Other");
        otherFile.FileName = "Other.xml";
        await store.AddTestCaseAsync(otherFile);

        var enabled = store.GetEnabledForFile("BillingService", "GetInvoice.xml");
        enabled.Should().ContainSingle(t => t.Id == "tc-1");
    }
}
