namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A single WSDL sync status point used for time-series timeline visualization.
/// Dates are stored as "yyyy-MM-dd" strings (relative to today in mock data).
/// </summary>
public class WsdlSyncHistoryPoint
{
    public string Id { get; set; } = "";
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "";
    public string SyncRecordId { get; set; } = "";
    public string Date { get; set; } = ""; // "yyyy-MM-dd"
    public string Status { get; set; } = "synced"; // "synced" | "failed" | "parsing"
    public string Details { get; set; } = "";

    /// <summary>
    /// Attempts to parse the stored date into a DateTime.
    /// </summary>
    public DateTime? TryGetDate()
        => DateTime.TryParseExact(Date, "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var dt) ? dt : null;
}
