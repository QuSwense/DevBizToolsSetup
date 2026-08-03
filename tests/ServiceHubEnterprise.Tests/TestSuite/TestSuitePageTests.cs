using ServiceHubEnterprise.TestSuite.Pages;

namespace ServiceHubEnterprise.Tests.TestSuite;

public class TestSuitePageTests : BunitTestBase
{
    [Fact]
    public void TestSuitesRendersPassRate()
    {
        var cut = Render<TestSuites>();

        cut.Markup.Should().Contain("4 suites");
        cut.Markup.Should().Contain("25 / 84 passing");
        cut.Markup.Should().Contain("Smoke Suite");
        cut.Markup.Should().Contain("Create Suite");
    }

    [Fact]
    public void ExecutionsHistoryRenders()
    {
        var cut = Render<ExecutionsHistory>();

        cut.Markup.Should().Contain("4 records");
        cut.Markup.Should().Contain("Execution ID");
        cut.Markup.Should().Contain("EX-001");
    }

    [Fact]
    public void TestCasesRenders()
    {
        var cut = Render<TestCases>();

        cut.Markup.Should().Contain("Test Cases");
        cut.Markup.Should().Contain("Create Test Case");
    }

    [Fact]
    public void SuccessCriteriaRenders()
    {
        var cut = Render<SuccessCriteria>();

        cut.Markup.Should().Contain("Success Criteria");
        cut.Markup.Should().Contain("Add Criterion");
    }
}
