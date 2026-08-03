using SidebarComponent = ServiceHubEnterprise.Web.Components.Layout.Sidebar;

namespace ServiceHubEnterprise.Tests.WebApp;

public class SidebarTests : BunitTestBase
{
    [Fact]
    public void RendersBrandAndPrimaryNavigation()
    {
        AddFakeNavigationManager();
        var cut = Render<SidebarComponent>();

        cut.Markup.Should().Contain("SERVICE HUB");
        cut.Markup.Should().Contain("Dashboard");
        cut.Markup.Should().Contain("SOAP");
        cut.Markup.Should().Contain("REST");
        cut.Markup.Should().Contain("File Management");
    }

    [Fact]
    public void ClickingDashboardNavigatesToRoot()
    {
        var nav = AddFakeNavigationManager();
        var cut = Render<SidebarComponent>();

        cut.FindAll("a.menu-item")[0].Click();

        nav.History.Select(h => h.Uri).Should().Contain("/");
    }

    [Fact]
    public void CollapseToggleTogglesSidebarState()
    {
        AddFakeNavigationManager();
        var cut = Render<SidebarComponent>();

        // Sidebar starts expanded; the collapse button collapses it.
        cut.Find("aside.sidebar").ClassList.Contains("collapsed").Should().BeFalse();
        cut.Find(".btn-collapse").Click();
        cut.Find("aside.sidebar").ClassList.Contains("collapsed").Should().BeTrue();
    }
}
