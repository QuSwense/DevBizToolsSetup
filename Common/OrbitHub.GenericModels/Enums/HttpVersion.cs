namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the HTTP version used for test case execution.
/// Maps to CK_ServiceTestSuiteExecutionAuditTestCaseLinks_HttpVersion:
/// 'HTTP/1.0', 'HTTP/1.1', 'HTTP/2', 'HTTP/3'.
/// </summary>
public enum HttpVersion
{
    /// <summary>HTTP/1.0</summary>
    Http10 = 0,

    /// <summary>HTTP/1.1</summary>
    Http11 = 1,

    /// <summary>HTTP/2</summary>
    Http2 = 2,

    /// <summary>HTTP/3</summary>
    Http3 = 3
}
