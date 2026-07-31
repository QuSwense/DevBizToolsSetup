using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the FileTypeBreakdown component.
/// </summary>
public partial class FileTypeBreakdown
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Files";

    /// <summary>
    /// Gets or sets the label for the total count unit (e.g. "request files").
    /// </summary>
    [Parameter] public string UnitLabel { get; set; } = "items";

    /// <summary>
    /// Gets or sets the list of file type entries.
    /// </summary>
    [Parameter]
    public IReadOnlyList<FileTypeItem> FileTypes { get; set; } = Array.Empty<FileTypeItem>();

    private int TotalCount => FileTypes.Sum(f => f.Count);

    /// <summary>
    /// Represents a single file type entry in the breakdown.
    /// </summary>
    public record FileTypeItem(string Type, int Count, string Color);
}
