namespace SoapApiProcessorTest.TestScenarios.SoapWsdlSyncTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class WsdlSyncTestGroup(
    SoapApplicationService appService,
    SoapOperationRepository operationRepository,
    HttpClient httpClient,
    ILogger<WsdlSyncTestGroup> logger)
{
    private const string DefaultUserId = "1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    3. WSDL SYNC & MULTI-SCHEMA TEST GROUP       ");
        Console.WriteLine("==================================================");

        try
        {
            await Test_SyncLiveWsdl_MultiSchemaExtraction();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] WSDL Sync Test threw unhandled exception: {ex.GetType().Name} - {ex.Message}");
        }
    }

    public async Task Test_SyncLiveWsdl_MultiSchemaExtraction()
    {
        logger.LogInformation("TEST: Syncing Live CustomerService WSDL (Port 7050) & verifying multi-schema extraction...");

        string appName = $"MultiSchemaApp_{Guid.NewGuid():N}"[..28];
        var regResult = await appService.RegisterApplicationAsync(new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            CreatedBy = DefaultUserId
        });

        if (!regResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] App Registration failed: {regResult.ErrorMessage}");
            return;
        }

        int appId = regResult.Data!.Id;

        using var response = await httpClient.GetAsync("http://localhost:7050/CustomerService.asmx?wsdl");
        using var wsdlStream = await response.Content.ReadAsStreamAsync();

        var syncInput = new SyncWsdlInput
        {
            AppId = appId,
            WsdlFileStream = wsdlStream,
            SyncedBy = DefaultUserId,
            ChangeComment = "Live Multi-Schema Sync"
        };

        var syncResult = await appService.SyncWsdlAsync(syncInput);

        if (!syncResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] WSDL Sync failed: {syncResult.ErrorMessage}");
            return;
        }

        Console.WriteLine($" -> WSDL Synced. Snapshot ID: {syncResult.Data!.Id} | Version: {syncResult.Data.Version}");

        var operations = await operationRepository.GetByAppIdAsync(appId);
        Console.WriteLine($" -> Operations Extracted: {operations.Count}");

        foreach (var op in operations)
        {
            Console.WriteLine($"    • Operation: {op.OperationName} | Action: {op.SoapAction}");
        }

        if (operations.Count >= 4)
        {
            Console.WriteLine(" [PASS] Live Multi-Schema WSDL parsed and extracted all operations successfully.");
        }
        else
        {
            Console.WriteLine($" [FAIL] Expected >= 4 operations, found {operations.Count}.");
        }
    }
}