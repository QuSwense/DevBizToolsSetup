using PdfProcessor.Models.Common;
using PdfProcessor.Models.Fields;

public record PdfChoiceField(
    string Name,
    string? MappingName,
    string? AlternateName,
    int PageNumber,
    BoundingBox Bounds,
    bool IsReadOnly,
    bool IsRequired,
    bool IsHidden,
    bool IsExportable,
    IReadOnlyList<string> SelectedValues,
    IReadOnlyList<PdfChoiceOption> AvailableOptions,
    bool IsMultiSelect,
    bool IsEditableDropdown
) : PdfFormField(Name, MappingName, AlternateName, PageNumber, Bounds, IsReadOnly, IsRequired, IsHidden, IsExportable);