using ServiceHubEnterprise.FileManagement.Core.Enums;

namespace ServiceHubEnterprise.FileManagement.Models;

/// <summary>
/// Represents a file item in the File Management feature.
/// </summary>
public class FileItem
{
    /// <summary>Unique identifier for the file.</summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>File name with extension.</summary>
    public string FileName { get; set; } = string.Empty;

    /// <summary>Display name of the linked application.</summary>
    public string AppName { get; set; } = string.Empty;

    /// <summary>File type classification.</summary>
    public FileType Type { get; set; } = FileType.Other;

    /// <summary>Human-readable file size (e.g. "2.4 KB").</summary>
    public string Size { get; set; } = string.Empty;

    /// <summary>Description of what the file is linked to (e.g. "PaymentService /payments POST").</summary>
    public string LinkedTo { get; set; } = string.Empty;

    /// <summary>Optional file content.</summary>
    public string? Content { get; set; }

    /// <summary>Optional description.</summary>
    public string? Description { get; set; }

    /// <summary>File status (active/inactive).</summary>
    public string Status { get; set; } = "active";

    /// <summary>Who created the file.</summary>
    public string CreatedBy { get; set; } = string.Empty;

    /// <summary>When the file was created.</summary>
    public string CreatedAt { get; set; } = string.Empty;

    /// <summary>Who last updated the file.</summary>
    public string UpdatedBy { get; set; } = string.Empty;

    /// <summary>When the file was last updated.</summary>
    public string UpdatedAt { get; set; } = string.Empty;

    /// <summary>Gets the file extension without the dot.</summary>
    public string Extension => Path.GetExtension(FileName).TrimStart('.').ToLowerInvariant();
}