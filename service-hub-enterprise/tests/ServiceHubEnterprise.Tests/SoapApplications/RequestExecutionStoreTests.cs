using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.Tests.Fixtures;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class RequestExecutionStoreTests : BunitTestBase
{
    private const string ExecutionsJson = """
[
  { "id": "re-1", "appName": "BillingService", "appType": "soap", "fileName": "GetInvoice.xml", "status": "passed", "executedAt": "2024-06-01 10:00:00", "durationMs": 120, "triggeredBy": "Priya Sharma" },
  { "id": "re-2", "appName": "BillingService", "appType": "SOAP", "fileName": "GetInvoice.xml", "status": "failed", "executedAt": "2024-06-02 10:00:00", "durationMs": 200, "triggeredBy": "Rahul Verma" },
  { "id": "re-3", "appName": "OrdersApi", "appType": "rest", "fileName": "orders.json", "status": "passed", "executedAt": "2024-06-03 10:00:00", "durationMs": 50, "triggeredBy": "Priya Sharma" }
]
""";

    [Fact]
    public void FiltersToSoapAppTypeCaseInsensitiveAndOrdersNewestFirst()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/Request/request-executions.json", ExecutionsJson));
        var store = new RequestExecutionStore(new MockDbLoader(db.BuildConfiguration()));

        store.SoapExecutions.Should().HaveCount(2);
        store.SoapExecutions.Select(e => e.Id)
            .Should().Equal("re-2", "re-1");
    }

    [Fact]
    public void HandlesEmptySource()
    {
        using var db = MockDbFixture.CreateTempMockDb(("Soap/Request/request-executions.json", "[]"));
        var store = new RequestExecutionStore(new MockDbLoader(db.BuildConfiguration()));

        store.SoapExecutions.Should().BeEmpty();
    }
}
