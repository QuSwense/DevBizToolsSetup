using OrbitHub.SoapApplications.Core.Enums;

namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A single request file inside an execution group, capturing its request/response
/// payloads, parsed fields, test-case extractions and execution logs.
/// </summary>
public class SoapExecutionFile
{
    /// <summary>Request file name (matches the Request Files page).</summary>
    public string FileName { get; set; } = "";

    /// <summary>Application the file belongs to.</summary>
    public string AppName { get; set; } = "";

    /// <summary>SOAP operation (API path) executed.</summary>
    public string Operation { get; set; } = "";

    /// <summary>Terminal/progress status: "queued" | "running" | "success" | "failed".</summary>
    public string Status { get; set; } = "queued";

    /// <summary>Current stage of the execution pipeline.</summary>
    public ExecutionStage Stage { get; set; } = ExecutionStage.Queued;

    /// <summary>Number of pipeline stages completed so far.</summary>
    public int StagesCompleted { get; set; }

    /// <summary>Total number of pipeline stages.</summary>
    public int StagesTotal { get; set; } = 7;

    /// <summary>Elapsed execution time in milliseconds.</summary>
    public long DurationMs { get; set; }

    /// <summary>The SOAP request payload sent (actual content or a synthesized envelope).</summary>
    public string RequestContent { get; set; } = "";

    /// <summary>The SOAP response payload received (simulated).</summary>
    public string ResponseContent { get; set; } = "";

    /// <summary>MIME type of the response payload (e.g. "text/xml").</summary>
    public string ResponseMimeType { get; set; } = "text/xml";

    /// <summary>Fields parsed out of the request/response for separate visibility.</summary>
    public List<SoapParsedField> ParsedFields { get; set; } = [];

    /// <summary>Results of running attached test-case extractors.</summary>
    public List<SoapExtractionResult> Extractions { get; set; } = [];

    /// <summary>Execution log entries (info/warning/error/request/response/assertion).</summary>
    public List<SoapExecutionLog> Logs { get; set; } = [];
}
