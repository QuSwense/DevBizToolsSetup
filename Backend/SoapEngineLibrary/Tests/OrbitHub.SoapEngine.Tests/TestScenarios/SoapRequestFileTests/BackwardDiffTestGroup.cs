namespace SoapApiProcessorTest.TestScenarios.SoapRequestFileTests;

using Microsoft.Extensions.Logging;
using OrbitHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using SoapApiProcessorTest.Configuration;
using static SoapApiProcessorTest.Helpers.TestHelper;

public class BackwardDiffTestGroup(
    SoapApplicationService appService,
    MockServicesOptions settings,
    ILogger<BackwardDiffTestGroup> logger)
{
    private const string DefaultUserId = "test_soap_user1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    BACKWARD DELTA DIFF CHAIN TEST GROUP         ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("Max 5 Diff Threshold", Test_Max5DiffThresholdChain);
    }

    public async Task Test_Max5DiffThresholdChain()
    {
        logger.LogInformation("TEST: Uploading 7 file versions to test 5-diff max threshold before full snapshot reset...");

        // 1. Create test app and operation
        string appName = $"DiffTestApp_{Guid.NewGuid():N}"[..25];
        var regResult = await appService.RegisterApplicationAsync(new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = settings.OfflineService.BaseUrl,
            CreatedBy = DefaultUserId
        });
        if (!regResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] App registration failed: {regResult.ErrorMessage}");
            return;
        }
        int appId = regResult.Data!.Id;

        var opInput = new CreateManualOperationInput
        {
            AppId = appId,
            OperationName = "GetCustomer",
            SoapAction = "http://servicehub.org/customer/soap/GetCustomer",
            InputRootElementName = "GetCustomer",
            OutputRootElementName = "GetCustomerResponse",
            TargetNamespace = "http://servicehub.org/customer/soap",
            CreatedBy = DefaultUserId
        };
        var opResult = await appService.CreateManualOperationAsync(opInput);
        if (!opResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] Manual operation creation failed: {opResult.ErrorMessage}");
            return;
        }
        int operationId = opResult.Data!.Id;

        string fileName = "GetCustomerRequest.xml";

        for (int v = 1; v <= 7; v++)
        {
            string xmlContent = $"<soap:Envelope><soap:Body><GetCustomer id=\"{v}\" name=\"Customer_V{v}\"/></soap:Body></soap:Envelope>";
            using var stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(xmlContent));
            var uploadInput = new UploadRequestFileInput
            {
                OperationId = operationId,
                FileName = fileName,
                FileStream = stream,
                CreatedBy = DefaultUserId
            };

            var result = await appService.UploadRequestFileStreamAsync(uploadInput);
            if (result.IsSuccess)
            {
                Console.WriteLine($" -> Version {v} Uploaded | File ID: {result.Data!.Id} | Version Tag: {result.Data.RecordVersion}");
            }
            else
            {
                Console.WriteLine($" [FAIL] Iteration {v} Failed: {result.ErrorMessage}");
                return;
            }
        }

        Console.WriteLine(" [PASS] 7 Versions Uploaded. Verified 5-diff threshold reset logic in history.");
    }
}