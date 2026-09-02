namespace SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class AppRegistrationTestGroup(
    SoapApplicationService appService,
    ILogger<AppRegistrationTestGroup> logger)
{
    private const string DefaultUserId = "1"; // Valid UserId matching FK_SoapApplications_CreatedBy_Users

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    1. APP REGISTRATION TEST GROUP                ");
        Console.WriteLine("==================================================");

        await ExecuteSafelyAsync("Register Basic Auth App", Test_RegisterBasicAuthApp_WithLiveWsdlUrl);
        await ExecuteSafelyAsync("Register OAuth2 App", Test_RegisterOAuthApp_WithLiveWsdlUrl);
        await ExecuteSafelyAsync("Register App Duplicate Name Block", Test_RegisterApp_DuplicateNameError);
        await ExecuteSafelyAsync("Register App Unreachable WSDL Block", Test_RegisterApp_InvalidWsdlUrlError);
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

    public async Task Test_RegisterBasicAuthApp_WithLiveWsdlUrl()
    {
        logger.LogInformation("TEST: Registering Application via Live Basic Auth WSDL (Port 7050)...");

        string appName = $"CustomerService_Basic_{Guid.NewGuid():N}"[..30];
        var input = new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            WsdlRelativeUrl = "?wsdl",
            Description = "Live Basic Auth Customer Service",
            CreatedBy = DefaultUserId
        };

        var result = await appService.RegisterApplicationAsync(input);

        if (result.IsSuccess)
        {
            Console.WriteLine($" [PASS] Registered App ID: {result.Data!.Id} | AppName: '{appName}' | Version: {result.Data.Version}");
        }
        else
        {
            Console.WriteLine($" [FAIL] {result.ErrorMessage}");
        }
    }

    public async Task Test_RegisterOAuthApp_WithLiveWsdlUrl()
    {
        logger.LogInformation("TEST: Registering Application via Live OAuth2 WSDL (Port 7051)...");

        string appName = $"DocumentService_OAuth_{Guid.NewGuid():N}"[..30];
        var input = new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = "http://localhost:7051/DocumentService.asmx",
            WsdlRelativeUrl = "?wsdl",
            Description = "Live OAuth2 Document Service",
            CreatedBy = DefaultUserId
        };

        var result = await appService.RegisterApplicationAsync(input);

        if (result.IsSuccess)
        {
            Console.WriteLine($" [PASS] Registered App ID: {result.Data!.Id} | AppName: '{appName}' | Version: {result.Data.Version}");
        }
        else
        {
            Console.WriteLine($" [FAIL] {result.ErrorMessage}");
        }
    }

    public async Task Test_RegisterApp_DuplicateNameError()
    {
        logger.LogInformation("TEST [Error Case]: Registering application with duplicate AppName...");

        string duplicateName = $"DuplicateApp_{Guid.NewGuid():N}"[..25];
        var input = new RegisterApplicationInput
        {
            AppName = duplicateName,
            BaseUrl = "http://localhost:7050/CustomerService.asmx",
            CreatedBy = DefaultUserId
        };

        var firstResult = await appService.RegisterApplicationAsync(input);
        if (!firstResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] Initial registration failed: {firstResult.ErrorMessage}");
            return;
        }

        var duplicateResult = await appService.RegisterApplicationAsync(input);

        if (!duplicateResult.IsSuccess)
        {
            Console.WriteLine($" [PASS] Duplicate registration blocked as expected. Error: {duplicateResult.ErrorMessage}");
        }
        else
        {
            Console.WriteLine(" [FAIL] System allowed duplicate AppName registration!");
        }
    }

    public async Task Test_RegisterApp_InvalidWsdlUrlError()
    {
        logger.LogInformation("TEST [Error Case]: Registering app with unreachable WSDL URL...");

        var input = new RegisterApplicationInput
        {
            AppName = $"InvalidWsdlApp_{Guid.NewGuid():N}"[..25],
            BaseUrl = "http://localhost:9999/NonExistentService.asmx",
            WsdlRelativeUrl = "?wsdl",
            CreatedBy = DefaultUserId
        };

        var result = await appService.RegisterApplicationAsync(input);

        if (!result.IsSuccess)
        {
            Console.WriteLine($" [PASS] Unreachable WSDL handled gracefully. Error: {result.ErrorMessage}");
        }
        else
        {
            Console.WriteLine(" [FAIL] System registered app with invalid WSDL endpoint!");
        }
    }
}