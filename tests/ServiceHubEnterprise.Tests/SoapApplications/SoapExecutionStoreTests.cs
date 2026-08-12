using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class SoapExecutionStoreTests
{
    private static SoapExecutionGroup Group(string id) => new()
    {
        Id = id,
        StartedAt = "2026-08-02 10:00:00",
        TriggeredBy = "Priya Sharma",
        Status = "completed",
        Files =
        [
            new SoapExecutionFile
            {
                FileName = "GetInvoice.xml",
                AppName = "BillingService",
                Operation = "GetInvoice",
                Status = "success",
                Stage = ExecutionStage.Complete,
                StagesCompleted = 7,
                StagesTotal = 7,
                RequestContent = "<req/>",
                ResponseContent = "<resp/>"
            }
        ]
    };

    [Fact]
    public async Task AddGroupAsync_PersistsToJson_AndReloads()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-executions.json", "[]"));
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        var store = new SoapExecutionStore(sp);

        await store.AddGroupAsync(Group("exg-1"));

        store.Groups.Should().ContainSingle();

        // A fresh store re-reads the persisted JSON.
        var reloaded = new SoapExecutionStore(sp);
        reloaded.Groups.Should().ContainSingle();
        reloaded.Groups[0].Id.Should().Be("exg-1");
        reloaded.Groups[0].Files[0].FileName.Should().Be("GetInvoice.xml");
        reloaded.Groups[0].Files[0].Stage.Should().Be(ExecutionStage.Complete);
        reloaded.Groups[0].Status.Should().Be("completed");
    }

    [Fact]
    public async Task GetGroupsForFile_FiltersAcrossGroups()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-executions.json", "[]"));
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        var store = new SoapExecutionStore(sp);

        await store.AddGroupAsync(Group("exg-1"));
        var other = Group("exg-2");
        other.Files[0].FileName = "Other.xml";
        await store.AddGroupAsync(other);

        store.GetGroupsForFile("GetInvoice.xml").Should().ContainSingle(g => g.Id == "exg-1");
    }

    [Fact]
    public async Task GetGroup_ReturnsGroupById()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/soap-executions.json", "[]"));
        var sp = new ServiceCollection()
            .AddDbContext<SoapDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        var store = new SoapExecutionStore(sp);

        await store.AddGroupAsync(Group("exg-1"));

        store.GetGroup("exg-1").Should().NotBeNull();
        store.GetGroup("missing").Should().BeNull();
    }
}
