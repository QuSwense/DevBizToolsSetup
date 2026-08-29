namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A single log entry produced while executing a SOAP request file.
/// Timestamps are stored as "yyyy-MM-dd HH:mm:ss" strings.
/// </summary>
public class SoapExecutionLog
{
    /// <summary>Stable id for the log entry.</summary>
    public string Id { get; set; } = "";

    /// <summary>When the log entry was created ("yyyy-MM-dd HH:mm:ss").</summary>
    public string Timestamp { get; set; } = "";

    /// <summary>
    /// Log type: "info" | "warning" | "error" | "request" | "response" | "assertion".
    /// </summary>
    public string Type { get; set; } = "info";

    /// <summary>Human-readable message.</summary>
    public string Message { get; set; } = "";
}
