using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Dashboard;
using ServiceHubEnterprise.Dashboard.Application.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.Dashboard;

public class DashboardServiceTests
{
    [Fact]
    public async Task MapsUsersAndResolvesCurrentUserFromFixture()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Dashboard/users.json", """
[
  { "name": "Priya Sharma", "role": "Superuser" },
  { "name": "Rahul Verma", "role": "User" }
]
"""));
        using var provider = BuildProvider(db.BuildConfiguration(currentUser: "Priya Sharma"));
        var svc = provider.GetRequiredService<IDashboardService>();

        var users = await svc.GetUsersAsync();

        users.Should().HaveCount(2);
        users[0].Name.Should().Be("Priya Sharma");
        users[0].Role.Should().Be("Superuser");

        var current = await svc.GetCurrentUserAsync();
        current.Should().NotBeNull();
        current!.Name.Should().Be("Priya Sharma");
        current!.Role.Should().Be("Superuser");
    }

    [Fact]
    public void ThrowsWhenMockDbPathIsMissing()
    {
        var services = new ServiceCollection();
        services.AddSingleton<IConfiguration>(new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>())
            .Build());
        services.AddDashboardFeature();

        using var provider = services.BuildServiceProvider();
        var act = () => provider.GetRequiredService<IDashboardService>();

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*MockDb:Path*");
    }

    private static ServiceProvider BuildProvider(IConfiguration config)
    {
        var services = new ServiceCollection();
        services.AddSingleton(config);
        services.AddDashboardFeature();
        return services.BuildServiceProvider();
    }
}
