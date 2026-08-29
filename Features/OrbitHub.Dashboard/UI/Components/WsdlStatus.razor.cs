using Microsoft.AspNetCore.Components;
using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the WsdlStatus component.
/// Shows the latest WSDL sync status per SOAP application.
/// </summary>
public partial class WsdlStatus
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "WSDL Sync Status";

    /// <summary>
    /// Gets or sets the WSDL sync records to render.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlRecordDto> Records { get; set; } = Array.Empty<WsdlRecordDto>();

    /// <summary>
    /// Gets the latest record per application, ordered by name.
    /// </summary>
    private IReadOnlyList<WsdlStatusItem> Items
    {
        get
        {
            return Records
                .GroupBy(r => r.AppName)
                .Select(g => g.OrderByDescending(r => r.UploadedAt).First())
                .OrderBy(r => r.AppName, StringComparer.OrdinalIgnoreCase)
                .Select(r => new WsdlStatusItem(
                    r.AppName,
                    r.Status,
                    r.Status.Equals("synced", StringComparison.OrdinalIgnoreCase),
                    FormatDate(r.UploadedAt),
                    r.VersionCount))
                .ToList();
        }
    }

    private int SyncedCount => Items.Count(i => i.Synced);

    private static string FormatDate(string value) =>
        value.Length >= 10 ? value[..10] : value;

    /// <summary>
    /// Represents the WSDL sync status for a single application.
    /// </summary>
    public record WsdlStatusItem(string AppName, string Status, bool Synced, string LastUpdated, int VersionCount);
}
