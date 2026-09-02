namespace SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class InspectWsdlTestGroup(
    SoapApplicationService appService,
    HttpClient httpClient,
    ILogger<InspectWsdlTestGroup> logger)
{
    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    10. WSDL INSPECTION TEST GROUP               ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("Inspect from URL (Port 7050)", Test_InspectWsdl_FromUrl);
        await ExecuteSafelyAsync("Inspect from File Stream", Test_InspectWsdl_FromFileStream);
    }

    private static async Task ExecuteSafelyAsync(string testName, Func<Task> testAction)
    {
        try
        {
            await testAction();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] '{testName}' threw unhandled exception: {ex.GetType().Name} - {ex.Message}");
        }
    }

    public async Task Test_InspectWsdl_FromUrl()
    {
        logger.LogInformation("TEST: Inspecting WSDL from live URL (Port 7050)...");
        var input = new InspectWsdlInput
        {
            WsdlUrl = "http://localhost:7050/CustomerService.asmx?wsdl"
        };

        var result = await appService.InspectWsdlOperationsAsync(input);
        if (result.IsSuccess && result.Data!.Count >= 4)
        {
            Console.WriteLine($" [PASS] Found {result.Data.Count} operations from URL.");
            foreach (var op in result.Data.Take(3))
                Console.WriteLine($"    • {op.OperationName} -> Action: {op.SoapAction}");
        }
        else
        {
            Console.WriteLine($" [FAIL] Inspection failed: {result.ErrorMessage}");
        }
    }

    public async Task Test_InspectWsdl_FromFileStream()
    {
        logger.LogInformation("TEST: Inspecting WSDL from file stream (Port 7050)...");
        using var response = await httpClient.GetAsync("http://localhost:7050/CustomerService.asmx?wsdl");
        using var stream = await response.Content.ReadAsStreamAsync();

        var input = new InspectWsdlInput
        {
            WsdlFileStream = stream
        };

        var result = await appService.InspectWsdlOperationsAsync(input);
        if (result.IsSuccess && result.Data!.Count >= 4)
        {
            Console.WriteLine($" [PASS] Found {result.Data.Count} operations from file stream.");
        }
        else
        {
            Console.WriteLine($" [FAIL] Inspection failed: {result.ErrorMessage}");
        }
    }
}