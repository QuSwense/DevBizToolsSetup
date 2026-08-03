using SettingsPage = ServiceHubEnterprise.Settings.Pages.Settings;

namespace ServiceHubEnterprise.Tests.Settings;

public class SettingsPageTests : BunitTestBase
{
    [Fact]
    public void SettingsRenders()
    {
        var cut = Render<SettingsPage>();

        cut.Markup.Should().Contain("Settings");
        cut.Markup.Should().Contain("Theme Preference");
        cut.Markup.Should().Contain("Save Settings");
    }
}
