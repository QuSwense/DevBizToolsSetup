namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// A test case optionally attached to a SOAP request file. It automates
/// verification of the response by running a set of <see cref="SoapExtractor"/>
/// definitions (XPath / JSON path / PDF field extraction) when the file executes.
/// A request file may have multiple test cases.
/// </summary>
public class SoapTestCase
{
    public string Id { get; set; } = "";

    public string Name { get; set; } = "";

    public string Description { get; set; } = "";

    /// <summary>Application the attached request file belongs to.</summary>
    public string AppName { get; set; } = "";

    /// <summary>Request file this test case is attached to.</summary>
    public string FileName { get; set; } = "";

    /// <summary>Disabled test cases are skipped during execution.</summary>
    public bool Enabled { get; set; } = true;

    public string CreatedBy { get; set; } = "";

    /// <summary>Creation timestamp ("yyyy-MM-dd HH:mm:ss").</summary>
    public string CreatedAt { get; set; } = "";

    public string? UpdatedBy { get; set; }

    public string? UpdatedAt { get; set; }

    /// <summary>Extractor definitions evaluated against request/response payloads.</summary>
    public List<SoapExtractor> Extractors { get; set; } = [];
}
