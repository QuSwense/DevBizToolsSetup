namespace SoapApiProcessorTest.TestScenarios.SoapRequestFileTests;

using System.Text;
using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class FileUploadTestGroup(
    SoapApplicationService appService,
    SoapFileCompressor compressor,
    ILogger<FileUploadTestGroup> logger)
{
    private const string DefaultUserId = "1";

    public async Task RunAllAsync()
    {
        Console.WriteLine("\n==================================================");
        Console.WriteLine("    FILE UPLOAD & COMPRESSION TEST GROUP          ");
        Console.WriteLine("==================================================");
        await ExecuteSafelyAsync("Upload & Compress", Test_UploadRequestFile_CompressionAndDecompression);
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

    public async Task Test_UploadRequestFile_CompressionAndDecompression()
    {
        logger.LogInformation("TEST: Uploading XML request payload, verifying GZip compression and lossless recovery...");

        // 1. Create a test app and a manual operation
        string appName = $"FileUploadApp_{Guid.NewGuid():N}"[..25];
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

        var opInput = new CreateManualOperationInput
        {
            AppId = appId,
            OperationName = "GetCustomerProfile",
            SoapAction = "http://servicehub.org/customer/soap/GetCustomerProfile",
            InputRootElementName = "GetCustomerProfile",
            OutputRootElementName = "GetCustomerProfileResponse",
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

        string fileName = $"GetProfile_{Guid.NewGuid():N}.xml";
        string rawXmlContent = """
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
        byte[] originalBytes = Encoding.UTF8.GetBytes(rawXmlContent);
        using var stream = new MemoryStream(originalBytes);

        var uploadInput = new UploadRequestFileInput
        {
            OperationId = operationId,
            FileName = fileName,
            FileStream = stream,
            CreatedBy = DefaultUserId
        };

        var result = await appService.UploadRequestFileStreamAsync(uploadInput);
        if (!result.IsSuccess)
        {
            Console.WriteLine($" [FAIL] File Upload failed: {result.ErrorMessage}");
            return;
        }

        var uploaded = result.Data!;
        Console.WriteLine($" -> Stored File ID: {uploaded.Id} | Version Tag: {uploaded.Version}");
        Console.WriteLine($" -> Uncompressed Size: {originalBytes.Length} bytes | Compressed Size: {uploaded.FileData.Length} bytes");

        byte[] decompressedBytes = compressor.Decompress(uploaded.FileData);
        string decompressedXml = Encoding.UTF8.GetString(decompressedBytes);

        if (string.Equals(rawXmlContent, decompressedXml, StringComparison.Ordinal))
        {
            Console.WriteLine(" [PASS] Lossless GZip compression and decompression verified.");
        }
        else
        {
            Console.WriteLine(" [FAIL] Decompressed payload does not match original XML!");
        }
    }
}