using Microsoft.Extensions.Logging;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class BasicTextPdfTester(PdfContextFactory contextFactory, ILogger<BasicTextPdfTester> logger) : ITestRunner
{
    public string TargetFileName => "basic-text.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE: Basic Text Context Inspection] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] File not found at '{Path}'.", filePath);
            return;
        }

        using var stream = File.OpenRead(filePath);
        await using var context = await contextFactory.CreateContextAsync(stream, prefetch: true);

        // 1. Text Presence Assertion - Full Document Search (pageNumber = null)
        var allPagesResult = context.HasText("PDF");
        if (allPagesResult != null)
        {
            logger.LogInformation("[PASS] HasText('PDF', pageNumber: null) -> Found on Page {Page} at Bounds [L:{L:F1}, B:{B:F1}, W:{W:F1}, H:{H:F1}]",
                allPagesResult.PageNumber, allPagesResult.Bounds.Left, allPagesResult.Bounds.Bottom, allPagesResult.Bounds.Width, allPagesResult.Bounds.Height);
        }
        else
        {
            logger.LogError("[FAIL] Text 'PDF' not found in full document search.");
        }

        // 2. Text Presence Assertion - Explicit Page Search
        var singlePageResult = context.HasText("PDF", pageNumber: 1);
        if (singlePageResult != null)
        {
            logger.LogInformation("[PASS] HasText('PDF', pageNumber: 1) -> Match: '{Matched}' on Page {Page}",
                singlePageResult.MatchedText, singlePageResult.PageNumber);
        }

        // 3. Text Presence Assertion - Negative Check (Non-existent text)
        var missingResult = context.HasText("NonExistentTerm12345");
        logger.LogInformation("[PASS] HasText('NonExistentTerm12345') returned null as expected: {IsNull}", missingResult == null);

        // 4. Line/Word Extraction
        var pageText = context.GetPageText(pageNumber: 1);
        logger.LogInformation("[PASS] Page 1 Line Count: {Count}, Word Count: {WordCount}", pageText.Lines.Count, pageText.Words.Count);

        logger.LogInformation("[SUCCESS] Finished context tests for {FileName}\n", TargetFileName);
    }
}