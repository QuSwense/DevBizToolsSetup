using ADViewerPage = ServiceHubEnterprise.ADViewer.Pages.ADViewer;

namespace ServiceHubEnterprise.Tests.ADViewer;

public class ADViewerPageTests : BunitTestBase
{
    [Fact]
    public void ADViewerRenders()
    {
        var cut = Render<ADViewerPage>();

        cut.Markup.Should().Contain("Active Directory Viewer");
        cut.Markup.Should().Contain("Search Directory");
        cut.Markup.Should().Contain("Browse Users");
    }
}
