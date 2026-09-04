using PdfProcessor.Models.Common;

namespace PdfProcessor.Models.Fields;

public record PdfTextField(
    string Name,
    string? MappingName,
    string? AlternateName,
    int PageNumber,
    BoundingBox Bounds,
    bool IsReadOnly,
    bool IsRequired,
    bool IsHidden,
    bool IsExportable,
    string DefaultValue,
    string Value,
    int? MaxLength,
    bool IsMultiline,
    bool IsPassword
) : PdfFormField(Name, MappingName, AlternateName, PageNumber, Bounds, IsReadOnly, IsRequired, IsHidden, IsExportable);