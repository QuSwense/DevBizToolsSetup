namespace SoapApiProcessorTest.TestScenarios.SoapExecutionTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Exceptions;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class OutboundSoapClientTestGroup(
    SoapClientService soapClient,
    SoapEncryptionService encryptionService,
    ILogger<OutboundSoapClientTestGroup> logger)
{
    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    5. OUTBOUND SOAP CLIENT & AUTH TEST GROUP     ");
        Console.WriteLine("==================================================");

        await ExecuteSafelyAsync("Basic Auth Outbound Call (Port 7050)", Test_BasicAuthCall_Port7050);
        await ExecuteSafelyAsync("OAuth2 Outbound Call (Port 7051)", Test_OAuth2Call_Port7051);
        await ExecuteSafelyAsync("Basic Auth Invalid Credentials Rejection", Test_BasicAuthCall_InvalidCredentials_ThrowsException);
        await ExecuteSafelyAsync("Unreachable Endpoint Rejection", Test_UnreachableEndpoint_ThrowsSoapHttpException);
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

    public async Task Test_BasicAuthCall_Port7050()
    {
        logger.LogInformation("TEST: Executing outbound HTTP SOAP call with Basic Auth (Port 7050)...");

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

        byte[] requestBytes = System.Text.Encoding.UTF8.GetBytes(requestXml);
        string encryptedAuth = encryptionService.EncryptObject(new BasicAuthCredentials
        {
            Username = "admin_user",
            Password = "SuperSecretPassword123!"
        });

        var response = await soapClient.ExecuteAsync(
            targetUrl: "http://localhost:7050/CustomerService.asmx",
            soapAction: "http://servicehub.org/customer/soap/ICustomerSoapService/GetCustomerProfile",
            requestBodyBytes: requestBytes,
            isCompressed: false,
            encryptedAuthJson: encryptedAuth,
            authType: EAuthenticationType.Basic);

        if (response.IsSuccess && response.HttpStatusCode == 200)
        {
            Console.WriteLine($" [PASS] Basic Auth SOAP Request Succeeded. Code: 200 | Latency: {response.LatencyMs}ms");
        }
        else
        {
            Console.WriteLine($" [FAIL] Basic Auth call failed with Status: {response.HttpStatusCode}");
        }
    }

    public async Task Test_OAuth2Call_Port7051()
    {
        logger.LogInformation("TEST: Executing outbound HTTP SOAP call with OAuth2 Bearer Token (Port 7051)...");

        string requestXml = """
            <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:doc="http://servicehub.org/document/soap">
                <soapenv:Header/>
                <soapenv:Body>
                   <doc:GetDocument>
                      <doc:request xmlns:types="http://servicehub.org/document/types">
                         <types:DocumentId>DOC-1001</types:DocumentId>
                      </doc:request>
                   </doc:GetDocument>
                </soapenv:Body>
            </soapenv:Envelope>
            """;

        byte[] requestBytes = System.Text.Encoding.UTF8.GetBytes(requestXml);
        string encryptedAuth = encryptionService.EncryptObject(new OAuth2Credentials
        {
            TokenEndpoint = "http://localhost:7051/connect/token",
            ClientId = "client_app_id_99",
            ClientSecret = "secret_key_888",
            GrantType = "client_credentials"
        });

        var response = await soapClient.ExecuteAsync(
            targetUrl: "http://localhost:7051/DocumentService.asmx",
            soapAction: "http://servicehub.org/document/soap/IDocumentSoapService/GetDocument",
            requestBodyBytes: requestBytes,
            isCompressed: false,
            encryptedAuthJson: encryptedAuth,
            authType: EAuthenticationType.OAuth2);

        if (response.IsSuccess && response.HttpStatusCode == 200)
        {
            Console.WriteLine($" [PASS] OAuth2 SOAP Request Succeeded. Code: 200 | Latency: {response.LatencyMs}ms");
        }
        else
        {
            Console.WriteLine($" [FAIL] OAuth2 call failed with Status: {response.HttpStatusCode}");
        }
    }

    public async Task Test_BasicAuthCall_InvalidCredentials_ThrowsException()
    {
        logger.LogInformation("TEST [Error Case]: Invoking port 7050 with wrong password...");

        byte[] requestBytes = "<soap:Envelope/>"u8.ToArray();
        string encryptedAuth = encryptionService.EncryptObject(new BasicAuthCredentials
        {
            Username = "admin_user",
            Password = "WrongPassword123"
        });

        try
        {
            await soapClient.ExecuteAsync(
                targetUrl: "http://localhost:7050/CustomerService.asmx",
                soapAction: "http://servicehub.org/customer/soap/ICustomerSoapService/GetCustomerProfile",
                requestBodyBytes: requestBytes,
                isCompressed: false,
                encryptedAuthJson: encryptedAuth,
                authType: EAuthenticationType.Basic);

            Console.WriteLine(" [FAIL] System allowed unauthorized call with wrong credentials!");
        }
        catch (SoapHttpException ex) when (ex.HttpStatusCode == System.Net.HttpStatusCode.Unauthorized)
        {
            Console.WriteLine($" [PASS] Invalid credentials properly rejected with 401 Unauthorized.");
        }
    }

    public async Task Test_UnreachableEndpoint_ThrowsSoapHttpException()
    {
        logger.LogInformation("TEST [Error Case]: Invoking unreachable endpoint on port 9999...");

        byte[] requestBytes = "<soap:Envelope/>"u8.ToArray();

        try
        {
            await soapClient.ExecuteAsync(
                targetUrl: "http://localhost:9999/NonExistent.asmx",
                soapAction: "http://tempuri.org/Action",
                requestBodyBytes: requestBytes,
                isCompressed: false,
                encryptedAuthJson: null,
                authType: null);

            Console.WriteLine(" [FAIL] Unreachable endpoint did not throw exception!");
        }
        catch (SoapHttpException ex)
        {
            Console.WriteLine($" [PASS] Unreachable endpoint caught gracefully: {ex.Message}");
        }
    }
}