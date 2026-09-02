namespace SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class FullApplicationTestGroup(
    SoapApplicationService appService,
    SoapOperationRepository operationRepository,
    ILogger<FullApplicationTestGroup> logger)
{
    private const string DefaultUserId = "1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    11. FULL APPLICATION CRUD TEST GROUP         ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("CreateFullApplication", Test_CreateFullApplication);
        await ExecuteSafelyAsync("UpdateFullApplication", Test_UpdateFullApplication);
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

    public async Task Test_CreateFullApplication()
    {
        logger.LogInformation("TEST: Creating full application with auth and operations...");

        string appName = $"FullApp_{Guid.NewGuid():N}"[..25];
        var createInput = new CreateFullApplicationInput
        {
            AppName = appName,
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            WsdlRelativeUrl = "?wsdl",
            Description = "Test full creation",
            CreatedBy = DefaultUserId,
            AuthType = EAuthenticationType.Basic,
            AuthCredentials = new BasicAuthCredentials
            {
                Username = "admin_user",
                Password = "SuperSecretPassword123!"
            },
            Operations =
            [
                new SaveOperationInput
                {
                    OperationName = "GetCustomerProfile",
                    SoapAction = "http://servicehub.org/customer/soap/ICustomerSoapService/GetCustomerProfile",
                    InputRootElementName = "GetCustomerProfile",
                    OutputRootElementName = "GetCustomerProfileResponse",
                    TargetNamespace = "http://servicehub.org/customer/soap"
                }
            ]
        };

        var result = await appService.CreateFullApplicationAsync(createInput);
        if (result.IsSuccess)
        {
            Console.WriteLine($" [PASS] Created App ID: {result.Data!.Id}, Version: {result.Data.Version}");
            var ops = await operationRepository.GetByAppIdAsync(result.Data.Id);
            Console.WriteLine($" -> Operations created: {ops.Count}");
        }
        else
        {
            Console.WriteLine($" [FAIL] {result.ErrorMessage}");
        }
    }

    public async Task Test_UpdateFullApplication()
    {
        logger.LogInformation("TEST: Updating full application (metadata, auth, operations)...");

        // First create an app
        string appName = $"UpdateApp_{Guid.NewGuid():N}"[..25];
        var createInput = new CreateFullApplicationInput
        {
            AppName = appName,
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            CreatedBy = DefaultUserId,
            Operations = new List<SaveOperationInput>
            {
                new SaveOperationInput
                {
                    OperationName = "InitialOp",
                    SoapAction = "http://tempuri.org/InitialOp",
                    InputRootElementName = "InitialOp",
                    OutputRootElementName = "InitialOpResponse",
                    TargetNamespace = "http://tempuri.org/"
                }
            }
        };
        var createResult = await appService.CreateFullApplicationAsync(createInput);
        if (!createResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] Setup failed: {createResult.ErrorMessage}");
            return;
        }
        int appId = createResult.Data!.Id;

        // Now update
        var updateInput = new UpdateFullApplicationInput
        {
            AppId = appId,
            AppName = appName + "_Updated",
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            Description = "Updated description",
            UpdatedBy = DefaultUserId,
            UpdateAuthentication = true,
            AuthType = EAuthenticationType.APIKey,
            AuthCredentials = new ApiKeyAuthCredentials
            {
                HeaderName = "X-API-KEY",
                ApiKey = "new_key_123",
                SendInHeader = true
            },
            Operations =
            [
                new SaveOperationInput
                {
                    OperationName = "InitialOp", // existing – will be updated
                    Description = "Updated description",
                    IsActive = true,
                    SoapAction = "http://tempuri.org/InitialOp_Updated",
                    InputRootElementName = "InitialOp",
                    OutputRootElementName = "InitialOpResponse",
                    TargetNamespace = "http://tempuri.org/"
                },
                new SaveOperationInput // new operation
                {
                    OperationName = "NewOp",
                    SoapAction = "http://tempuri.org/NewOp",
                    InputRootElementName = "NewOp",
                    OutputRootElementName = "NewOpResponse",
                    TargetNamespace = "http://tempuri.org/"
                }
            ]
        };

        var updateResult = await appService.UpdateFullApplicationAsync(updateInput);
        if (updateResult.IsSuccess)
        {
            Console.WriteLine($" [PASS] App updated successfully.");
            var ops = await operationRepository.GetByAppIdAsync(appId);
            Console.WriteLine($" -> Operations after update: {ops.Count} (should be 2)");
        }
        else
        {
            Console.WriteLine($" [FAIL] {updateResult.ErrorMessage}");
        }
    }
}