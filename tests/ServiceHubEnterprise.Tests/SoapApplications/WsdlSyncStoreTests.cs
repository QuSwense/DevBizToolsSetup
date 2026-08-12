using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Builders;
using ServiceHubEnterprise.Tests.Fixtures;
using Microsoft.EntityFrameworkCore;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class WsdlSyncStoreTests : BunitTestBase
{
    private static WsdlSyncStore CreateStore(TempMockDb db)
    {
        var sp = new ServiceCollection()
            .AddDbContext<WsdlDbContext>(opts => opts.UseSqlServer("Data Source=:memory:"))
            .AddSingleton<IConfiguration>(db.BuildConfiguration())
            .BuildServiceProvider();
        return new WsdlSyncStore(sp);
    }

    [Fact]
    public void GetRecordsForAppFiltersAndOrdersNewestFirst()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json",
                """[{"id":"r1","appId":"app-1","appName":"A","uploadedAt":"2024-01-01"},{"id":"r2","appId":"app-1","appName":"A","uploadedAt":"2024-06-01"},{"id":"r3","appId":"app-2","appName":"B","uploadedAt":"2024-03-01"}]"""));
        var store = CreateStore(db);

        var records = store.GetRecordsForApp("app-1");

        records.Select(r => r.Id).Should().Equal("r2", "r1");
    }

    [Fact]
    public void GetVersionsForSyncOrdersByVersionDesc()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-versions.json",
                """[{"id":"v1","syncRecordId":"s1","versionNumber":1},{"id":"v3","syncRecordId":"s1","versionNumber":3},{"id":"v2","syncRecordId":"s1","versionNumber":2}]"""));
        var store = CreateStore(db);

        var versions = store.GetVersionsForSync("s1");

        versions.Select(v => v.Id).Should().Equal("v3", "v2", "v1");
    }

    [Fact]
    public void GetTemplatesOrdersByName()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-templates.json",
                """[{"id":"t2","name":"Zulu"},{"id":"t1","name":"Alpha"}]"""));
        var store = CreateStore(db);

        var templates = store.GetTemplates();

        templates.Select(t => t.Name).Should().Equal("Alpha", "Zulu");
    }

    [Fact]
    public void GetTemplateFindsByIdAndReturnsNullForMissing()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-templates.json",
                """[{"id":"t1","name":"Alpha"}]"""));
        var store = CreateStore(db);

        store.GetTemplate("t1")?.Name.Should().Be("Alpha");
        store.GetTemplate("nope").Should().BeNull();
    }

    [Fact]
    public void ResolveEffectiveTemplateReturnsSelfWhenNoParent()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-templates.json",
                """[{"id":"t1","name":"Alpha"}]"""));
        var store = CreateStore(db);

        var template = store.GetTemplate("t1")!;
        store.ResolveEffectiveTemplate(template).Should().BeSameAs(template);
    }

    [Fact]
    public void ResolveEffectiveTemplateReturnsParent()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-templates.json",
                """[{"id":"base","name":"Base"},{"id":"child","name":"Child","extendsTemplateId":"base"}]"""));
        var store = CreateStore(db);

        var child = store.GetTemplate("child")!;
        store.ResolveEffectiveTemplate(child)?.Id.Should().Be("base");
    }

    [Fact]
    public void ResolveVariablesWalksChainAndDeDuplicates()
    {
        using var db = MockDbFixture.CreateTempMockDb(
            ("Wsdl/wsdl-records.json", "[]"),
            ("Wsdl/wsdl-templates.json",
                """[{"id":"base","name":"Base","variables":["customer_id","amount"]},{"id":"child","name":"Child","extendsTemplateId":"base","variables":["amount","currency"]}]"""));
        var store = CreateStore(db);

        var child = store.GetTemplate("child")!;
        var vars = store.ResolveVariables(child);

        vars.Select(v => v.Name).Should().BeEquivalentTo("amount", "currency", "customer_id");
        vars.First(v => v.Name == "customer_id").Label.Should().Be("Customer Id");
    }

    [Fact]
    public void ParseWsdlVariablesExtractsTagContentAndAttributes()
    {
        const string wsdl = """
<wsdl>
  <message name="GetInvoiceRequest">
    <part name="customer_id" type="xsd:string"/>
  </message>
  <operation name="GetInvoice" soapAction="https://example.com/GetInvoice"/>
</wsdl>
""";

        var vars = WsdlSyncStore.ParseWsdlVariables(wsdl);

        vars.Should().Contain("getinvoice");
        vars.Should().Contain("customer_id");
        vars.Should().Contain("xsd_string");
    }

    [Fact]
    public void ParseWsdlVariablesReturnsEmptyForWhitespace()
    {
        WsdlSyncStore.ParseWsdlVariables("   ").Should().BeEmpty();
        WsdlSyncStore.ParseWsdlVariables("").Should().BeEmpty();
        WsdlSyncStore.ParseWsdlVariables(null!).Should().BeEmpty();
    }

    [Theory]
    [InlineData("Customer ID", "customer_id")]
    [InlineData("GetInvoice", "getinvoice")]
    [InlineData("Hello, World!", "hello_world")]
    [InlineData("", "")]
    [InlineData("   ", "")]
    public void ToVariableNameNormalizesText(string input, string expected)
    {
        WsdlSyncStore.ToVariableName(input).Should().Be(expected);
    }

    [Theory]
    [InlineData("customer_id", "Customer Id")]
    [InlineData("amount", "Amount")]
    [InlineData("", "")]
    public void ToLabelFormatsVariableName(string input, string expected)
    {
        WsdlSyncStore.ToLabel(input).Should().Be(expected);
    }

    [Fact]
    public void ApplyVariablesSubstitutesKnownAndLeavesUnknown()
    {
        var result = WsdlSyncStore.ApplyVariables("Hello {{name}}, id={{id}}", new Dictionary<string, string>
        {
            ["name"] = "World"
        });

        result.Should().Be("Hello World, id={{id}}");
    }

    [Fact]
    public void ApplyVariablesReturnsContentWhenNoValues()
    {
        WsdlSyncStore.ApplyVariables("{{a}}", new Dictionary<string, string>()).Should().Be("{{a}}");
        WsdlSyncStore.ApplyVariables(null!, new Dictionary<string, string> { ["a"] = "1" }).Should().BeNull();
    }
}
