using Microsoft.Extensions.Logging;
using PdfProcessor.Models.Common;
using PdfProcessor.Models.Fields;
using UglyToad.PdfPig;
using UglyToad.PdfPig.AcroForms.Fields;

namespace PdfProcessor.Services.Internal;

public class AcroFormExtractor(ILogger<AcroFormExtractor> logger)
{
    public IReadOnlyList<PdfFormField> ExtractFields(PdfDocument document, int? pageNumber = null)
    {
        logger.LogDebug("Extracting AcroForm fields (Page Filter: {Page})...", pageNumber);
        var extractedFields = new List<PdfFormField>();

        if (!document.TryGetForm(out var acroForm) || acroForm == null)
        {
            logger.LogInformation("No AcroForm structure detected in document.");
            return extractedFields;
        }

        foreach (var field in acroForm.Fields)
        {
            try
            {
                var processed = ProcessField(field);
                if (processed != null)
                {
                    if (!pageNumber.HasValue || processed.PageNumber == pageNumber.Value)
                    {
                        extractedFields.Add(processed);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to extract properties for field '{FieldName}'", field.Information?.PartialName);
            }
        }

        return extractedFields;
    }

    private static PdfFormField? ProcessField(AcroFieldBase field)
    {
        var bounds = field.Bounds.HasValue
            ? new BoundingBox(field.Bounds.Value.Left, field.Bounds.Value.Top, field.Bounds.Value.Width, field.Bounds.Value.Height, field.Bounds.Value.Bottom, field.Bounds.Value.Right)
            : new BoundingBox(0, 0, 0, 0, 0, 0);

        int pageNum = 1;
        bool isReadOnly = false;
        bool isRequired = false;
        bool isHidden = false;
        bool isExportable = true;
        string fieldName = field.Information?.PartialName ?? string.Empty;
        string? mappingName = field.Information?.MappingName;
        string? alternateName = field.Information?.AlternateName;

        return field switch
        {
            AcroTextField textField => new PdfTextField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, textField.Value ?? string.Empty, textField.Value ?? string.Empty, null, textField.IsMultiline, false),
            AcroComboBoxField comboBox => new PdfChoiceField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, comboBox.SelectedOptions ?? Array.Empty<string>(), new List<PdfChoiceOption>(), false, true),
            AcroListBoxField listBox => new PdfChoiceField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, listBox.SelectedOptions ?? Array.Empty<string>(), new List<PdfChoiceOption>(), true, false),
            AcroCheckboxField chkField => new PdfButtonField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, ButtonType.CheckBox, chkField.IsChecked, chkField.CurrentValue?.Data ?? "Yes", null),
            AcroPushButtonField => new PdfButtonField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, ButtonType.PushButton, false, string.Empty, null),
            AcroSignatureField => new PdfButtonField(fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, ButtonType.PushButton, false, string.Empty, "Signature"),
            _ => ProcessGenericField(field, fieldName, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable)
        };
    }

    private static PdfFormField ProcessGenericField(AcroFieldBase field, string name, string? mappingName, string? alternateName, int pageNum, BoundingBox bounds, bool isReadOnly, bool isRequired, bool isHidden, bool isExportable)
    {
        if (field.FieldType == AcroFieldType.PushButton || field.FieldType == AcroFieldType.Checkbox || field.FieldType == AcroFieldType.RadioButton)
        {
            return new PdfButtonField(name, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, ButtonType.RadioButton, false, string.Empty, null);
        }
        return new PdfTextField(name, mappingName, alternateName, pageNum, bounds, isReadOnly, isRequired, isHidden, isExportable, string.Empty, string.Empty, null, false, false);
    }
}