namespace SoapApiProcessorTest.Configuration;

/// <summary>Endpoint URLs for a mock service referenced by a test group.</summary>
public class MockServiceEndpoint
{
    public string BaseUrl { get; set; } = string.Empty;
    public string WsdlUrl { get; set; } = string.Empty;
    public string TokenEndpoint { get; set; } = string.Empty;
}

/// <summary>Strongly typed view of the "MockServices" section in appsettings.json.</summary>
public class MockServicesOptions
{
    public const string SectionName = "MockServices";

    public MockServiceEndpoint BasicAuthService { get; set; } = new();
    public MockServiceEndpoint OAuth2Service { get; set; } = new();
    public MockServiceEndpoint UnreachableService { get; set; } = new();
    public MockServiceEndpoint OfflineService { get; set; } = new();
}
