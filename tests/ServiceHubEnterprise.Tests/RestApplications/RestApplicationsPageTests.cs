using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.RestApplications.Pages;

namespace ServiceHubEnterprise.Tests.RestApplications;

public class RestApplicationsPageTests : BunitTestBase
{
    private void RegisterOptionalConfig()
        => Services.AddSingleton<IConfiguration>(new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Users:CurrentUser"] = "Priya Sharma" })
            .Build());

    [Fact]
    public void ApplicationsRendersTable()
    {
        RegisterOptionalConfig();
        var cut = Render<Applications>();

        cut.Markup.Should().Contain("Add Application");
        cut.Markup.Should().Contain("App Name");
        cut.Markup.Should().Contain("PaymentService");
    }

    [Fact]
    public void RequestFilesRendersAfterLoad()
    {
        RegisterOptionalConfig();
        var cut = Render<RequestFiles>();

        // This page simulates a 1500ms load before showing the toolbar.
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Upload File"), TimeSpan.FromSeconds(5));
        cut.Markup.Should().Contain("File Name");
        cut.Markup.Should().Contain("API Path");
    }

    [Fact]
    public void SwaggerSyncRenders()
    {
        var cut = Render<SwaggerSync>();

        cut.Markup.Should().Contain("Swagger Sync");
        cut.Markup.Should().Contain("Import Swagger URL");
    }

    [Fact]
    public void TemplatesRenders()
    {
        var cut = Render<Templates>();

        cut.Markup.Should().Contain("3 templates");
        cut.Markup.Should().Contain("Create Template");
        cut.Markup.Should().Contain("Payment Success Template");
    }

    [Fact]
    public void ExecuteHistoryRenders()
    {
        var cut = Render<ExecuteHistory>();

        cut.Markup.Should().Contain("4 records");
        cut.Markup.Should().Contain("Execution ID");
        cut.Markup.Should().Contain("EX-001");
    }
}
