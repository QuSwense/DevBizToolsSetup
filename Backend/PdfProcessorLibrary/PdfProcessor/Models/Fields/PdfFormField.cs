using PdfProcessor.Models.Common;

namespace PdfProcessor.Models.Fields;

/// <summary>
/// Abstract base class representing common PDF AcroForm field properties.
/// </summary>
public abstract record PdfFormField(
    string Name,
    string? MappingName,
    string? AlternateName,
    int PageNumber,
    BoundingBox Bounds,
    bool IsReadOnly,
    bool IsRequired,
    bool IsHidden,
    bool IsExportable
);