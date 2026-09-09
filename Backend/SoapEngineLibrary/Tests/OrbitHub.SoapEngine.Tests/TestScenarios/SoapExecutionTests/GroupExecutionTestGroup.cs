namespace SoapApiProcessorTest.TestScenarios.SoapExecutionTests;

using Microsoft.Extensions.Logging;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using SoapApiProcessorTest.Configuration;

public class GroupExecutionTestGroup(
    SoapApplicationService appService,
    ServiceOperationRepository operationRepository,
    ServiceExecutionAuditRepository executionRepository,
    SoapExecutionGroupRunner runner,
    HttpClient httpClient,
    MockServicesOptions settings,
    ILogger<GroupExecutionTestGroup> logger)
{
    private const string DefaultUserId = "test_soap_user1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    6. BATCH GROUP EXECUTION ORCHESTRATOR TEST    ");
        Console.WriteLine("==================================================");

        try
        {
            await Test_FullEndToEnd_GroupExecution();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] Group Execution Test threw unhandled exception: {ex.GetType().Name} - {ex.Message}");
        }
    }

    public async Task Test_FullEndToEnd_GroupExecution()
    {
        logger.LogInformation("TEST: Setting up full execution group and running batch execution against Port 7050...");

        string appName = $"BatchExecApp_{Guid.NewGuid():N}"[..25];
        var appReg = await appService.RegisterApplicationAsync(new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = settings.BasicAuthService.BaseUrl,
            CreatedBy = DefaultUserId
        });

        if (!appReg.IsSuccess)
        {
            Console.WriteLine($" [FAIL] App setup failed: {appReg.ErrorMessage}");
            return;
        }

        int appId = appReg.Data!.Id;

        await appService.ConfigureAuthenticationAsync(new ConfigureAuthInput
        {
            AppId = appId,
            ConfiguredBy = DefaultUserId,
            Credentials = new BasicAuthCredentials
            {
                Username = "admin_user",
                Password = "SuperSecretPassword123!"
            }
        });

        using var response = await httpClient.GetAsync(settings.BasicAuthService.WsdlUrl);
        using var wsdlStream = await response.Content.ReadAsStreamAsync();
        await appService.SyncWsdlAsync(new SyncWsdlInput
        {
            AppId = appId,
            WsdlFileStream = wsdlStream,
            SyncedBy = DefaultUserId
        });

        var operations = await operationRepository.GetByAppIdAsync(appId);
        if (operations.Count == 0)
        {
            Console.WriteLine(" [FAIL] No operations found after WSDL sync!");
            return;
        }

        string requestXml = """
            <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cust="http://servicehub.org/customer/soap">
                <soapenv:Header/>
                <soapenv:Body>
                   <cust:GetCustomerProfile>
                      <cust:request xmlns:types="http://servicehub.org/customer/types">
                         <types:CustomerId>101</types:CustomerId>
                         <types:RequestorId>TEST_RUNNER</types:RequestorId>
                         <types:IncludeTransactionHistory>true</types:IncludeTransactionHistory>
                      </cust:request>
                   </cust:GetCustomerProfile>
                </soapenv:Body>
            </soapenv:Envelope>
            """;

        using var fileStream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(requestXml));
        var uploadResult = await appService.UploadRequestFileStreamAsync(new UploadRequestFileInput
        {
            OperationId = operations[0].Id,
            FileName = "BatchRequest.xml",
            FileStream = fileStream,
            CreatedBy = DefaultUserId
        });

        int requestFileId = uploadResult.Data!.Id;

        // Create execution audit (replaces old SoapExecutionGroup)
        var audit = await executionRepository.CreateAuditAsync(
            $"BatchGroup_{Guid.NewGuid():N}"[..25],
            DefaultUserId);

        // Create response file link (replaces old SoapExecutionGroupItem)
        var link = new DirectExecutionAuditResponseFileLink
        {
            DirectExecutionAuditId = audit.Id,
            ServiceRequestFileId = requestFileId,
            ExecutedAt = DateTime.UtcNow,
            ExecutionStatus = "Pending"
        };
        await executionRepository.AddResponseLinkAsync(link);

        var runResult = await runner.RunGroupAsync(audit.Id, executedBy: DefaultUserId);

        if (runResult.IsSuccess)
        {
            Console.WriteLine($" [PASS] End-to-End Batch Run Succeeded. Run ID: {runResult.Data!.Id} | Status: {runResult.Data.ExecutionStatus}");
        }
        else
        {
            Console.WriteLine($" [FAIL] Batch Run Execution Failed: {runResult.ErrorMessage}");
        }
    }
}