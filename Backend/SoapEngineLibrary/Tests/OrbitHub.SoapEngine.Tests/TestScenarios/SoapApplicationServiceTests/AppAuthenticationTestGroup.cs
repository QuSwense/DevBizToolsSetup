namespace OrbitHub.SoapEngine.Tests.TestScenarios.SoapApplicationServiceTests;

using Microsoft.Extensions.Logging;
using OrbitHub.SoapEngine.Core.Models.Inputs;
using OrbitHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using SoapApiProcessorTest.Configuration;
using static SoapApiProcessorTest.Helpers.TestHelper;

public class AppAuthenticationTestGroup(
    SoapApplicationService appService,
    MockServicesOptions settings,
    ILogger<AppAuthenticationTestGroup> logger)
{
    private const string DefaultUserId = "test_soap_user1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    2. APP AUTHENTICATION TEST GROUP              ");
        Console.WriteLine("==================================================");

        int appId = 0;
        try
        {
            appId = await CreateTestAppAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] Failed to set up test application: {ex.Message}");
            return;
        }

        if (appId == 0) return;

        await ExecuteSafelyAsync("Configure Basic Auth", () => Test_ConfigureBasicAuthentication(appId));
        await ExecuteSafelyAsync("Configure OAuth2", () => Test_ConfigureOAuth2Authentication(appId));
        await ExecuteSafelyAsync("Configure API Key", () => Test_ConfigureApiKeyAuthentication(appId));
    }

    private async Task<int> CreateTestAppAsync()
    {
        var reg = await appService.RegisterApplicationAsync(new RegisterApplicationInputModel
        {
            AppName = $"AuthTestApp_{Guid.NewGuid():N}"[..25],
            BaseUrl = settings.BasicAuthService.BaseUrl,
            CreatedBy = DefaultUserId
        });

        return reg.IsSuccess ? reg.Data!.Id : 0;
    }

    public async Task Test_ConfigureBasicAuthentication(int appId)
    {
        logger.LogInformation("TEST: Encrypting and saving Basic Auth credentials...");

        var input = new ConfigureAuthInputModel
        {
            AppId = appId,
            ConfiguredBy = DefaultUserId,
            Credentials = new BasicAuthCredentialsInputModel
            {
                Username = "admin_user",
                Password = "SuperSecretPassword123!"
            }
        };

        var result = await appService.ConfigureAuthenticationAsync(input);
        Console.WriteLine(result.IsSuccess ? " [PASS] Basic Auth Encrypted & Persisted." : $" [FAIL] {result.ErrorMessage}");
    }

    public async Task Test_ConfigureOAuth2Authentication(int appId)
    {
        logger.LogInformation("TEST: Encrypting and saving OAuth2 Client Credentials...");

        var input = new ConfigureAuthInputModel
        {
            AppId = appId,
            ConfiguredBy = DefaultUserId,
            Credentials = new OAuth2CredentialsInputModel
            {
                TokenEndpoint = settings.OAuth2Service.TokenEndpoint,
                ClientId = "client_app_id_99",
                ClientSecret = "secret_key_888",
                GrantType = "client_credentials",
                Scope = "soap:read soap:write"
            }
        };

        var result = await appService.ConfigureAuthenticationAsync(input);
        Console.WriteLine(result.IsSuccess ? " [PASS] OAuth2 Encrypted & Persisted." : $" [FAIL] {result.ErrorMessage}");
    }

    public async Task Test_ConfigureApiKeyAuthentication(int appId)
    {
        logger.LogInformation("TEST: Encrypting and saving API Key Credentials...");

        var input = new ConfigureAuthInputModel
        {
            AppId = appId,
            ConfiguredBy = DefaultUserId,
            Credentials = new ApiKeyAuthCredentialsInputModel
            {
                HeaderName = "X-API-KEY",
                ApiKey = "secret_api_key_12345",
                SendInHeader = true
            }
        };

        var result = await appService.ConfigureAuthenticationAsync(input);
        Console.WriteLine(result.IsSuccess ? " [PASS] API Key Encrypted & Persisted." : $" [FAIL] {result.ErrorMessage}");
    }
}