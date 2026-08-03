using Microsoft.Extensions.Configuration;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class MockDbLoaderTests : BunitTestBase
{
    private sealed class Widget
    {
        public string Name { get; set; } = "";
        public int Count { get; set; }
    }

    [Fact]
    public void ThrowsWhenMockDbPathMissing()
    {
        var emptyConfig = new Microsoft.Extensions.Configuration.ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>())
            .Build();

        var act = () => new MockDbLoader(emptyConfig);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*MockDb:Path*");
    }

    [Fact]
    public void ThrowsWhenDirectoryDoesNotExist()
    {
        var config = BuildConfiguration(System.IO.Path.Combine(System.IO.Path.GetTempPath(), "she-missing-" + Guid.NewGuid().ToString("N")));

        var act = () => new MockDbLoader(config);

        act.Should().Throw<System.IO.DirectoryNotFoundException>();
    }

    [Fact]
    public async Task LoadJsonAsyncDeserializesCaseInsensitive()
    {
        using var db = MockDbFixture.CreateTempMockDb(("widgets.json", """[{"name":"Billing","count":3}]"""));
        var loader = new MockDbLoader(db.BuildConfiguration());

        var widgets = await loader.LoadJsonAsync<Widget[]>("widgets.json");

        widgets.Should().HaveCount(1);
        widgets[0].Name.Should().Be("Billing");
        widgets[0].Count.Should().Be(3);
    }

    [Fact]
    public async Task LoadJsonAsyncReturnsDefaultForMissingFile()
    {
        using var db = MockDbFixture.CreateTempMockDb();
        var loader = new MockDbLoader(db.BuildConfiguration());

        var result = await loader.LoadJsonAsync<Widget[]>("nope.json");

        result.Should().BeNull();
    }

    [Fact]
    public async Task LoadWsdlContentResolvesAndCachesByKey()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-content-map.json", """{"basic":"Wsdl/wsdl_basic.wsdl"}"""),
            ("Wsdl/wsdl_basic.wsdl", "<wsdl>hello</wsdl>"));
        var loader = new MockDbLoader(db.BuildConfiguration());

        var content = await loader.LoadWsdlContentAsync("basic");

        content.Should().Be("<wsdl>hello</wsdl>");

        // Cached: modify the file and confirm the cache is returned.
        db.WriteFile("Wsdl/wsdl_basic.wsdl", "CHANGED");
        var cached = await loader.LoadWsdlContentAsync("basic");
        cached.Should().Be("<wsdl>hello</wsdl>");
    }

    [Fact]
    public async Task LoadWsdlContentReturnsEmptyForUnknownKey()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-content-map.json", """{"basic":"Wsdl/wsdl_basic.wsdl"}"""),
            ("Wsdl/wsdl_basic.wsdl", "<wsdl/>"));
        var loader = new MockDbLoader(db.BuildConfiguration());

        var content = await loader.LoadWsdlContentAsync("missing");

        content.Should().Be("");
    }

    [Fact]
    public async Task PreloadAllWsdlContentCachesAllEntries()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-content-map.json", """{"a":"Wsdl/a.wsdl","b":"Wsdl/b.wsdl"}"""),
            ("Wsdl/a.wsdl", "<a/>"),
            ("Wsdl/b.wsdl", "<b/>"));
        var loader = new MockDbLoader(db.BuildConfiguration());

        await loader.PreloadAllWsdlContentAsync();

        (await loader.LoadWsdlContentAsync("a")).Should().Be("<a/>");
        (await loader.LoadWsdlContentAsync("b")).Should().Be("<b/>");
    }
}
