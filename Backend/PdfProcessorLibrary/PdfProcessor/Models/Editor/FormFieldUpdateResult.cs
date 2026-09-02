namespace PdfProcessor.Models.Editor;

/// <summary>
/// Result summary of an AcroForm field update operation.
/// </summary>
public record FormFieldUpdateResult(
    string FieldName,
    bool IsUpdated,
    string? OldValue = null,
    string? NewValue = null,
    string? StatusMessage = null
);