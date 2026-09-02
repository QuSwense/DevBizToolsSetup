namespace PdfProcessor.Models.Editor;

/// <summary>
/// Configuration flags for PDF export/save operations.
/// </summary>
public record PdfSaveOptions
{
    /// <summary>
    /// Flattens form fields into static page content upon saving if set to true.
    /// </summary>
    public bool FlattenFormFields { get; init; } = false;

    /// <summary>
    /// Re-compresses PDF stream objects during export.
    /// </summary>
    public bool CompressStream { get; init; } = true;
}