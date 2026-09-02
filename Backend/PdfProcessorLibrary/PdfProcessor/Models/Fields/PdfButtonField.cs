using PdfProcessor.Models.Common;
using PdfProcessor.Models.Fields;

public record PdfButtonField(
    string Name,
    string? MappingName,
    string? AlternateName,
    int PageNumber,
    BoundingBox Bounds,
    bool IsReadOnly,
    bool IsRequired,
    bool IsHidden,
    bool IsExportable,
    ButtonType Type,
    bool IsChecked,
    string OnStateExportValue,
    string? ActionTargetUrl
) : PdfFormField(Name, MappingName, AlternateName, PageNumber, Bounds, IsReadOnly, IsRequired, IsHidden, IsExportable);