namespace SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class ManualOperationTestGroup(
    SoapApplicationService appService,
    ILogger<ManualOperationTestGroup> logger)
{
    private const string DefaultUserId = "1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    MANUAL OPERATION CREATION TEST GROUP          ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("Create Manual Operation", Test_CreateManualOperation_WithoutWsdl);
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

    public async Task Test_CreateManualOperation_WithoutWsdl()
    {
        logger.LogInformation("TEST: Creating manual SOAP operation without a WSDL...");

        // 1. Create a test application
        string appName = $"ManualOpApp_{Guid.NewGuid():N}"[..25];
        var regResult = await appService.RegisterApplicationAsync(new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = "https://fake.service.local/",
            CreatedBy = DefaultUserId
        });
        if (!regResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] App registration failed: {regResult.ErrorMessage}");
            return;
        }
        int appId = regResult.Data!.Id;
        Console.WriteLine($" -> Test App Created (ID: {appId})");

        // 2. Create manual operation
        var input = new CreateManualOperationInput
        {
            AppId = appId,
            OperationName = "ExecuteManualTransfer",
            SoapAction = "http://finance.org/services/ExecuteManualTransfer",
            InputRootElementName = "ExecuteManualTransferRequest",
            OutputRootElementName = "ExecuteManualTransferResponse",
            TargetNamespace = "http://finance.org/services",
            CreatedBy = DefaultUserId
        };

        var result = await appService.CreateManualOperationAsync(input);
        if (result.IsSuccess)
        {
            Console.WriteLine($" [PASS] Manually created operation '{result.Data!.OperationName}' with ID: {result.Data.Id}");
        }
        else
        {
            Console.WriteLine($" [FAIL] {result.ErrorMessage}");
        }
    }
}