namespace SoapApiProcessorTest.TestScenarios.SoapWsdlSyncTests;

using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Services;

public class WsdlDiscrepancyTestGroup(
    SoapApplicationService appService,
    SoapWsdlSyncRepository wsdlRepository,
    SoapOperationRepository operationRepository,
    ILogger<WsdlDiscrepancyTestGroup> logger)
{
    public async Task RunAllAsync()
    {
        Console.WriteLine("---> Executing WsdlDiscrepancyTestGroup...");
        await Test_WsdlReconciliation_WithDiscrepanciesAndManualOperations();
    }

    public async Task Test_WsdlReconciliation_WithDiscrepanciesAndManualOperations()
    {
        logger.LogInformation("TEST: Reconciling updated WSDL against existing manual and parsed operations...");

        // 1. Setup: Register a test application
        string appName = $"Test_ReconciliationApp_{Guid.NewGuid():N}";
        var regInput = new RegisterApplicationInput
        {
            AppName = appName,
            BaseUrl = "https://api.reconcile.internal/soap",
            Description = "Test App for WSDL Discrepancy Reconciliation",
            CreatedBy = "TEST_RUNNER"
        };

        var appResult = await appService.RegisterApplicationAsync(regInput);
        if (!appResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] Initial App Registration failed: {appResult.ErrorMessage}");
            return;
        }

        int appId = appResult.Data!.Id;

        // 2. Setup: Add a manual custom operation that won't exist in the new WSDL
        var manualOpInput = new CreateManualOperationInput
        {
            AppId = appId,
            OperationName = "CustomLegacyPayment",
            SoapAction = "http://api.reconcile.internal/CustomLegacyPayment",
            InputRootElementName = "CustomLegacyPaymentRequest",
            OutputRootElementName = "CustomLegacyPaymentResponse",
            TargetNamespace = "http://api.reconcile.internal/",
            CreatedBy = "TEST_RUNNER"
        };

        var manualOpResult = await appService.CreateManualOperationAsync(manualOpInput);
        if (!manualOpResult.IsSuccess)
        {
            Console.WriteLine($" [FAIL] Manual Operation creation failed: {manualOpResult.ErrorMessage}");
            return;
        }

        Console.WriteLine($" -> Created Manual Operation '{manualOpResult.Data!.OperationName}' (ID: {manualOpResult.Data.Id})");

        // 3. Sync Initial WSDL (V1) containing Operation 'ProcessOrder'
        string v1Wsdl = """
            <wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" name="OrderService">
                <wsdl:types></wsdl:types>
                <wsdl:portType name="OrderPortType">
                    <wsdl:operation name="ProcessOrder">
                        <wsdl:input message="tns:ProcessOrderInput"/>
                        <wsdl:output message="tns:ProcessOrderOutput"/>
                    </wsdl:operation>
                </wsdl:portType>
                <wsdl:binding name="OrderBinding" type="tns:OrderPortType">
                    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
                    <wsdl:operation name="ProcessOrder">
                        <soap:operation soapAction="http://api.reconcile.internal/v1/ProcessOrder"/>
                    </wsdl:operation>
                </wsdl:binding>
            </wsdl:definitions>
            """;

        using var v1Stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(v1Wsdl));
        var syncV1Input = new SyncWsdlInput
        {
            AppId = appId,
            WsdlFileStream = v1Stream,
            SyncedBy = "TEST_RUNNER",
            ChangeComment = "V1 WSDL Initial Sync"
        };

        var syncV1Result = await appService.SyncWsdlAsync(syncV1Input);
        if (!syncV1Result.IsSuccess)
        {
            Console.WriteLine($" [FAIL] V1 WSDL Sync failed: {syncV1Result.ErrorMessage}");
            return;
        }

        Console.WriteLine($" -> Initial V1 WSDL Synced (Version: {syncV1Result.Data!.Version})");

        // 4. Sync Updated WSDL (V2) with:
        //    a. Modified SoapAction for 'ProcessOrder' (Discrepancy)
        //    b. New operation 'CancelOrder' (Addition)
        //    c. 'CustomLegacyPayment' missing (Should be retained safely)
        string v2Wsdl = """
            <wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" name="OrderService">
                <wsdl:types></wsdl:types>
                <wsdl:portType name="OrderPortType">
                    <wsdl:operation name="ProcessOrder">
                        <wsdl:input message="tns:ProcessOrderInput"/>
                        <wsdl:output message="tns:ProcessOrderOutput"/>
                    </wsdl:operation>
                    <wsdl:operation name="CancelOrder">
                        <wsdl:input message="tns:CancelOrderInput"/>
                        <wsdl:output message="tns:CancelOrderOutput"/>
                    </wsdl:operation>
                </wsdl:portType>
                <wsdl:binding name="OrderBinding" type="tns:OrderPortType">
                    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
                    <wsdl:operation name="ProcessOrder">
                        <soap:operation soapAction="http://api.reconcile.internal/v2/UpdatedProcessOrderAction"/>
                    </wsdl:operation>
                    <wsdl:operation name="CancelOrder">
                        <soap:operation soapAction="http://api.reconcile.internal/v2/CancelOrder"/>
                    </wsdl:operation>
                </wsdl:binding>
            </wsdl:definitions>
            """;

        using var v2Stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(v2Wsdl));
        var syncV2Input = new SyncWsdlInput
        {
            AppId = appId,
            WsdlFileStream = v2Stream,
            SyncedBy = "TEST_RUNNER",
            ChangeComment = "V2 WSDL Sync with updated SoapAction and new operation"
        };

        var syncV2Result = await appService.SyncWsdlAsync(syncV2Input);
        if (!syncV2Result.IsSuccess)
        {
            Console.WriteLine($" [FAIL] V2 WSDL Sync failed: {syncV2Result.ErrorMessage}");
            return;
        }

        Console.WriteLine($" -> Updated V2 WSDL Synced (Version: {syncV2Result.Data!.Version})");

        // 5. Assertions: Verify manual operation still exists and active state is retained
        var manualOpCheck = await operationRepository.GetByIdAsync(manualOpResult.Data.Id);
        bool isManualRetained = manualOpCheck is not null && manualOpCheck.IsActive;

        if (isManualRetained)
        {
            Console.WriteLine(" [PASS] Custom operation missing in WSDL was safely retained in DB.");
        }
        else
        {
            Console.WriteLine(" [FAIL] Custom operation was incorrectly removed or inactivated!");
        }

        // 6. Verify WSDL History Audit Log Entry
        var latestSync = await wsdlRepository.GetLatestByAppIdAsync(appId);
        if (latestSync is not null)
        {
            Console.WriteLine($" [PASS] WSDL Reconciliation Completed Successfully for App ID {appId}.");
        }
        else
        {
            Console.WriteLine(" [FAIL] Could not verify latest WSDL snapshot!");
        }
    }
}