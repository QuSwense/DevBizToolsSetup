using Microsoft.Extensions.Logging;
using PdfProcessor.Services;
using PdfProcessor.TestRunner.Abstractions;

namespace PdfProcessor.TestRunner.Testers;

public class StatelessServiceTester(PdfProcessorService pdfProcessor, ILogger<StatelessServiceTester> logger) : ITestRunner
{
    public string TargetFileName => "basic-text.pdf";

    public async Task RunAsync(string basePdfDirectory)
    {
        var filePath = Path.Combine(basePdfDirectory, TargetFileName);
        logger.LogInformation("==========================================");
        logger.LogInformation("[SUITE 4: Stateless Single-Call Service] Target: {FileName}", TargetFileName);
        logger.LogInformation("==========================================");

        if (!File.Exists(filePath))
        {
            logger.LogWarning("[SKIP] File not found at '{Path}'. Skipping stateless tests.", filePath);
            return;
        }

        using var stream = File.OpenRead(filePath);

        // Single-call extraction through IPdfProcessorService
        var pageText = await pdfProcessor.ExtractPageTextAsync(stream, pageNumber: 1);
        logger.LogInformation("[PASS] Single-Call Page Text Line Count: {Count}", pageText.Lines.Count);

        stream.Position = 0;
        bool hasText = await pdfProcessor.HasTextAsync(stream, "PDF", pageNumber: 1);
        logger.LogInformation("[PASS] Single-Call HasText Check: {Result}", hasText);

        logger.LogInformation("[SUCCESS] Stateless service test completed.\n");
    }
}