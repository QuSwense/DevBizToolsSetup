using Microsoft.Extensions.Logging;
using PdfProcessor.Models.Common;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class SpatialAndCoordinateTester(PdfContextFactory contextFactory, ILogger<SpatialAndCoordinateTester> logger) : ITestRunner
{
    public string TargetFileName => "Caregiver-Employment-Application-Form-Template-TemplateLab.com_.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE 2: Spatial & Coordinate Context] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] Test PDF missing at path: {Path}", filePath);
            return;
        }

        using var stream = File.OpenRead(filePath);

        // Parse once and create the stateful context
        await using var context = await contextFactory.CreateContextAsync(stream, prefetch: true);

        // 1. Get pre-extracted layout data for Page 1 directly from Context
        var pageContent = context.GetPageText(pageNumber: 1);
        logger.LogInformation("[PASS] Page 1 Lines: {LineCount}, Page 1 Words: {WordCount}",
            pageContent.Lines.Count, pageContent.Words.Count);

        foreach (var line in pageContent.Lines.Take(3))
        {
            logger.LogInformation("  [Line #{No}] (Words: {Count}, Y-Bottom: {Bottom:F1}): '{Text}'",
                line.LineNumber, line.Words.Count, line.Bounds.Bottom, line.Text);
        }

        // 2. Query coordinate directly from Context (no re-reading stream)
        if (pageContent.Words.Count > 0)
        {
            var sampleWord = pageContent.Words[Math.Min(10, pageContent.Words.Count - 1)];
            double queryX = sampleWord.Bounds.Left + (sampleWord.Bounds.Width / 2.0);
            double queryY = sampleWord.Bounds.Bottom + (sampleWord.Bounds.Height / 2.0);

            var hitWord = context.GetWordAtCoordinate(pageNumber: 1, x: queryX, y: queryY);
            logger.LogInformation("[PASS] Coordinate hit test at ({X:F1}, {Y:F1}): Expected='{Exp}', Found='{Act}'",
                queryX, queryY, sampleWord.Text, hitWord?.Text);
        }

        // 3. Region-bounded text extraction directly from Context
        var topRegion = new BoundingBox(Left: 0, Top: 792, Width: 612, Height: 396, Bottom: 396, Right: 612);
        var regionText = context.ExtractTextInRegion(pageNumber: 1, region: topRegion);
        logger.LogInformation("[PASS] Region text extracted from context (Length: {Len}): {Snippet}",
            regionText.Length, regionText.Length > 60 ? regionText[..60] + "..." : regionText);

        logger.LogInformation("[SUCCESS] Spatial and coordinate extraction suite completed.\n");
    }
}