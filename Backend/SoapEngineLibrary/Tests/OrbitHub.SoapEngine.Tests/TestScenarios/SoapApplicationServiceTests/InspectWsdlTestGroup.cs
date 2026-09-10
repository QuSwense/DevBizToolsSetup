namespace OrbitHub.SoapEngine.Tests.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using OrbitHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using SoapApiProcessorTest.Configuration;
using static SoapApiProcessorTest.Helpers.TestHelper;

public class InspectWsdlTestGroup(
    SoapApplicationService appService,
    HttpClient httpClient,
    MockServicesOptions settings,
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

    public async Task Test_InspectWsdl_FromUrl()
    {
        logger.LogInformation("TEST: Inspecting WSDL from live URL (Port 7050)...");
        var input = new InspectWsdlInputModel
        {
            WsdlUrl = settings.BasicAuthService.WsdlUrl
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
        using var response = await httpClient.GetAsync(settings.BasicAuthService.WsdlUrl);
        using var stream = await response.Content.ReadAsStreamAsync();

        var input = new InspectWsdlInputModel
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