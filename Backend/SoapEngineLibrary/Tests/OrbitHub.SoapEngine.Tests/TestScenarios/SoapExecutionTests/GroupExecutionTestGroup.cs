namespace SoapApiProcessorTest.TestScenarios.SoapExecutionTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class GroupExecutionTestGroup(
    SoapApplicationService appService,
    SoapOperationRepository operationRepository,
    SoapExecutionRepository executionRepository,
    SoapExecutionGroupRunner runner,
    HttpClient httpClient,
    ILogger<GroupExecutionTestGroup> logger)
{
    private const string DefaultUserId = "1";

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
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
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

        using var response = await httpClient.GetAsync("http://localhost:7050/CustomerService.asmx?wsdl");
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

        var group = new SoapExecutionGroup
        {
            AppId = appId,
            GroupName = $"BatchGroup_{Guid.NewGuid():N}"[..25],
            Description = "Automated Integration Test Batch Group",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = DefaultUserId
        };

        var groupItems = new[]
        {
            new SoapExecutionGroupItem
            {
                RequestFileId = requestFileId,
                ExecutionOrder = 1,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = DefaultUserId
            }
        };

        var createdGroup = await executionRepository.CreateGroupAsync(group, groupItems);
        var runResult = await runner.RunGroupAsync(createdGroup.Id, executedBy: DefaultUserId);

        if (runResult.IsSuccess)
        {
            Console.WriteLine($" [PASS] End-to-End Batch Run Succeeded. Run ID: {runResult.Data!.Id} | Status: {runResult.Data.RunStatus}");
        }
        else
        {
            Console.WriteLine($" [FAIL] Batch Run Execution Failed: {runResult.ErrorMessage}");
        }
    }
}