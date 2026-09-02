using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PdfProcessor.DependencyInjection;
using PdfProcessor.TestRunner.Abstractions;
using PdfProcessor.TestRunner.Testers;

namespace PdfProcessor.TestRunner;

public class Program
{
    public static async Task Main(string[] args)
    {
        var host = CreateHostBuilder(args).Build();
        var logger = host.Services.GetRequiredService<ILogger<Program>>();

        logger.LogInformation("==========================================");
        logger.LogInformation("    Modular PDF Context & Rule Test Suite ");
        logger.LogInformation("==========================================\n");

        string samplePdfsDirectory = Path.Combine(AppContext.BaseDirectory, "sample_pdfs");
        if (!Directory.Exists(samplePdfsDirectory))
        {
            samplePdfsDirectory = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "sample_pdfs"));
        }

        logger.LogInformation("Target PDF Directory: {Directory}\n", samplePdfsDirectory);

        var allRunners = host.Services.GetServices<ITestRunner>().ToList();
        var selectedRunners = FilterTestRunners(allRunners, args, logger);

        if (!selectedRunners.Any())
        {
            logger.LogWarning("No matching test runners found to execute.");
            PrintAvailableRunners(allRunners, logger);
            return;
        }

        logger.LogInformation("Executing {Count} test runner(s)...\n", selectedRunners.Count);

        foreach (var runner in selectedRunners)
        {
            try
            {
                await runner.RunAsync(samplePdfsDirectory);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[FAIL] Test runner '{RunnerName}' failed for target: {FileName}",
                    runner.GetType().Name, runner.TargetFileName);
            }
        }

        logger.LogInformation("All selected PDF test runs completed successfully.");
    }

    private static List<ITestRunner> FilterTestRunners(List<ITestRunner> allRunners, string[] args, ILogger logger)
    {
        if (args.Length == 0)
        {
            return allRunners;
        }

        var selected = new List<ITestRunner>();

        foreach (var arg in args)
        {
            if (int.TryParse(arg, out int index) && index >= 1 && index <= allRunners.Count)
            {
                selected.Add(allRunners[index - 1]);
                continue;
            }

            var matchedByName = allRunners.Where(r =>
                r.GetType().Name.Equals(arg, StringComparison.OrdinalIgnoreCase) ||
                r.GetType().Name.StartsWith(arg, StringComparison.OrdinalIgnoreCase)).ToList();

            if (matchedByName.Any())
            {
                selected.AddRange(matchedByName);
            }
            else
            {
                logger.LogWarning("Unknown test runner filter argument: '{Arg}'", arg);
            }
        }

        return [.. selected.Distinct()];
    }

    private static void PrintAvailableRunners(List<ITestRunner> runners, ILogger logger)
    {
        logger.LogInformation("Available Test Runners:");
        for (int i = 0; i < runners.Count; i++)
        {
            logger.LogInformation("  [{Index}] {Name} (Target: {Target})",
                i + 1, runners[i].GetType().Name, runners[i].TargetFileName);
        }
    }

    public static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            .ConfigureServices((_, services) =>
            {
                services.AddLogging(builder => builder.AddConsole());

                // Registers IPdfContextFactory, IPdfEditorContextFactory, and IPdfProcessorService
                services.AddPdfProcessor();

                // Register all test runner implementations
                services.AddTransient<ITestRunner, BasicTextPdfTester>();
                services.AddTransient<ITestRunner, StatelessServiceTester>();
                services.AddTransient<ITestRunner, FormFieldsInspectionTester>();
                services.AddTransient<ITestRunner, SpatialAndCoordinateTester>();
                services.AddTransient<ITestRunner, ValidationAndSearchTester>();
                services.AddTransient<ITestRunner, PdfFormEditingTester>();
            });
}