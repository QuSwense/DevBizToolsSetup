using Microsoft.AspNetCore.Components;
using MainLayoutComponent = ServiceHubEnterprise.Web.Components.Layout.MainLayout;

namespace ServiceHubEnterprise.Tests.WebApp;

public class MainLayoutTests : BunitTestBase
{
    [Fact]
    public void RendersHeaderAndBody()
    {
        AddFakeNavigationManager(); // MainLayout hosts the Sidebar which needs NavigationManager.
        var cut = Render<MainLayoutComponent>(p => p
            .Add(x => x.Title, "Dashboard")
            .Add(x => x.Body, b => b.AddMarkupContent(0, "<p class=\"body-content\">page body</p>")));

        cut.Find(".main-header-title").TextContent.Should().Be("Dashboard");
        cut.Find(".header-user-name").TextContent.Should().Be("Admin • Priya Sharma");
        cut.Find(".main-body .body-content").TextContent.Should().Be("page body");
    }

    [Fact]
    public void DefaultTitleIsServiceHubEnterprise()
    {
        AddFakeNavigationManager();
        var cut = Render<MainLayoutComponent>(p => p
            .Add(x => x.Body, (RenderFragment)(b => { })));

        cut.Find(".main-header-title").TextContent.Should().Be("Service Hub Enterprise");
    }
}
