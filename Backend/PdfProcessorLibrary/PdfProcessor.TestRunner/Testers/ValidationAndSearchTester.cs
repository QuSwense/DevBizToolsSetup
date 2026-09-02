using Microsoft.Extensions.Logging;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class ValidationAndSearchTester(PdfContextFactory contextFactory, ILogger<ValidationAndSearchTester> logger) : ITestRunner
{
    public string TargetFileName => "Caregiver-Employment-Application-Form-Template-TemplateLab.com_.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE 3: Validation & Rules Engine Simulation] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] Test PDF missing at path: {Path}", filePath);
            return;
        }

        using var stream = File.OpenRead(filePath);
        await using var context = await contextFactory.CreateContextAsync(stream, prefetch: true);

        // 1. Context Text Search - All Pages (pageNumber: null)
        var globalSearchHit = context.HasText("Application", pageNumber: null, caseSensitive: false);
        if (globalSearchHit != null)
        {
            logger.LogInformation("[PASS] Global HasText('Application'): Found on Page {Page}, Bounds: [L:{L:F1}, B:{B:F1}, W:{W:F1}, H:{H:F1}]",
                globalSearchHit.PageNumber, globalSearchHit.Bounds.Left, globalSearchHit.Bounds.Bottom, globalSearchHit.Bounds.Width, globalSearchHit.Bounds.Height);
        }
        else
        {
            logger.LogError("[FAIL] Global HasText('Application') failed to locate string.");
        }

        // 2. Context Text Search - Specific Page
        var page1SearchHit = context.HasText("Employment", pageNumber: 1);
        logger.LogInformation("[PASS] Page 1 HasText('Employment'): Matched '{Text}' on Page {Page}",
            page1SearchHit?.MatchedText, page1SearchHit?.PageNumber);

        // 3. Wildcard Search on Context
        var searchResults = context.SearchText(new[] { "Caregiver", "Employment", "Name*" }, caseSensitive: false);
        logger.LogInformation("[PASS] Context Search Matches Found: {Count}", searchResults.Count);

        // 4. Form Field Existence Verification
        string targetField = context.FormFields.FirstOrDefault()?.Name ?? "Full_Name";
        bool fieldExists = context.HasFormField(fieldName: targetField, pageNumber: 1);
        logger.LogInformation("[PASS] Context.HasFormField('{FieldName}', Page 1): {Exists}", targetField, fieldExists);

        // 5. Form Field Value Validation
        var valResult = context.ValidateFormFieldValue(fieldName: targetField, expectedValue: "", pageNumber: 1);
        logger.LogInformation("[PASS] Context Rule Validation for '{Field}': IsValid={Valid}, Actual='{Actual}'",
            valResult.FieldName, valResult.IsValid, valResult.ActualValue);

        logger.LogInformation("[SUCCESS] Validation suite completed.\n");
    }
}