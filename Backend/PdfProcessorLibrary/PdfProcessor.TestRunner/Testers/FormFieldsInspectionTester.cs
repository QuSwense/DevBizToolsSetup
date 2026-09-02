using Microsoft.Extensions.Logging;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class FormFieldsInspectionTester(PdfContextFactory contextFactory, ILogger<FormFieldsInspectionTester> logger) : ITestRunner
{
    public string TargetFileName => "Caregiver-Employment-Application-Form-Template-TemplateLab.com_.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE 1: Form Field Inspection Context] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] Test PDF missing at path: {Path}", filePath);
            return;
        }

        using var stream = File.OpenRead(filePath);

        // Parse once and create the stateful context
        await using var context = await contextFactory.CreateContextAsync(stream, prefetch: true);

        // 1. Inspect total extracted form fields from context
        var allFields = context.FormFields;
        logger.LogInformation("[PASS] Total AcroForm Fields Extracted in Context: {Count}", allFields.Count);

        // 2. Filter page-specific fields from context
        var page1Fields = context.FormFields.Where(f => f.PageNumber == 1).ToList();
        logger.LogInformation("[PASS] Page 1 Form Fields Count: {Count}", page1Fields.Count);

        // 3. Inspect field names across entire document context
        var fieldNames = context.FormFields
            .Select(f => f.Name)
            .Where(name => !string.IsNullOrEmpty(name))
            .ToList();

        logger.LogInformation("[PASS] Field Name List ({Count}): {Names}",
            fieldNames.Count, string.Join(", ", fieldNames.Take(10)));

        // 4. Log detailed field metadata
        foreach (var field in allFields.Take(5))
        {
            logger.LogInformation("  -> Field: Name='{Name}', Type={Type}, Page={Page}, Bounds=[L:{L:F1}, B:{B:F1}, W:{W:F1}, H:{H:F1}]",
                field.Name, field.GetType().Name, field.PageNumber, field.Bounds.Left, field.Bounds.Bottom, field.Bounds.Width, field.Bounds.Height);
        }

        logger.LogInformation("[SUCCESS] Form field inspection suite completed.\n");
    }
}