using Microsoft.Extensions.Logging;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.GenericModels.Models;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapExecutionGroupRunner(
    ServiceExecutionAuditRepository executionRepository,
    ServiceApplicationRepository appRepository,
    ServiceOperationRepository operationRepository,
    ServiceRequestFileRepository requestFileRepository,
    SoapClientService soapClientService,
    SoapFileCompressor compressor,
    ILogger<SoapExecutionGroupRunner> logger)
{
    public async Task<ResultModel<DirectExecutionAudit>> RunGroupAsync(
        int groupId,
        string executedBy,
        CancellationToken cancellationToken = default)
    {
        // Validate inputs
        if (groupId <= 0)
            return ResultModel<DirectExecutionAudit>.Failure("groupId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(executedBy))
            return ResultModel<DirectExecutionAudit>.Failure("executedBy is required.");

        logger.LogInformation("Initiating batch execution run for Execution Group ID: {GroupId} by {ExecutedBy}", groupId, executedBy);

        var group = await executionRepository.GetAuditByIdAsync(groupId, cancellationToken);
        if (group is null)
            return ResultModel<DirectExecutionAudit>.Failure($"Execution group with ID {groupId} was not found.");

        var groupLinks = await executionRepository.GetLinksByAuditIdAsync(groupId, cancellationToken);
        if (groupLinks.Count == 0)
            return ResultModel<DirectExecutionAudit>.Failure($"Execution group {groupId} contains no registered items.");

        bool hasFailures = false;

        try
        {
            foreach (var link in groupLinks)
            {
                if (cancellationToken.IsCancellationRequested)
                {
                    logger.LogWarning("Execution run ID {RunId} cancelled by caller.", group.Id);
                    await executionRepository.CompleteAuditAsync(group.Id, "Cancelled", cancellationToken: cancellationToken);
                    return ResultModel<DirectExecutionAudit>.Failure("Execution run was cancelled.");
                }

                bool itemSuccess = await ExecuteItemAsync(group.Id, link, executedBy, cancellationToken);
                if (!itemSuccess)
                    hasFailures = true;
            }

            var finalStatus = hasFailures ? "Failed" : "Completed";
            await executionRepository.CompleteAuditAsync(group.Id, finalStatus, cancellationToken: cancellationToken);
            group.ExecutionStatus = finalStatus;
            group.ExecutionCompletedAt = DateTime.UtcNow;
            return ResultModel<DirectExecutionAudit>.Success(group);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled failure during execution run ID {RunId}", group.Id);
            await executionRepository.CompleteAuditAsync(group.Id, "Failed", $"Unhandled error: {ex.Message}", cancellationToken);
            return ResultModel<DirectExecutionAudit>.Failure($"Execution run failed: {ex.Message}");
        }
    }

    private async Task<bool> ExecuteItemAsync(
        int auditId,
        DirectExecutionAuditResponseFileLink link,
        string executedBy,
        CancellationToken cancellationToken)
    {
        logger.LogInformation("Executing Response Link ID: {LinkId} (Request File ID: {RequestFileId}) in Audit ID: {AuditId}", link.Id, link.ServiceRequestFileId, auditId);

        var requestFile = await requestFileRepository.GetByIdAsync(link.ServiceRequestFileId, cancellationToken);
        if (requestFile is null || !requestFile.IsActive)
        {
            logger.LogError("Request file ID {RequestFileId} is inactive or missing.", link.ServiceRequestFileId);
            return false;
        }

        var operation = await operationRepository.GetByIdAsync(requestFile.ServiceOperationId, cancellationToken);
        if (operation is null)
        {
            logger.LogError("Parent Operation ID {OperationId} missing for Request File {RequestFileId}.", requestFile.ServiceOperationId, link.ServiceRequestFileId);
            return false;
        }

        var application = await appRepository.GetByIdAsync(operation.ServiceApplicationId, cancellationToken);
        if (application is null || !application.IsActive)
        {
            logger.LogError("Parent Application ID {AppId} missing or inactive.", operation.ServiceApplicationId);
            return false;
        }

        var authConfig = await appRepository.GetAuthenticationByAppIdAsync(application.Id, cancellationToken);
        EAuthenticationType? authType = null;
        if (authConfig is not null && Enum.TryParse<EAuthenticationType>(authConfig.AuthenticationType, out var parsedAuthType))
            authType = parsedAuthType;

        try
        {
            SoapExecutionResponseOutputModel response = await soapClientService.ExecuteAsync(
                targetUrl: application.BaseUrl,
                soapAction: operation.EndpointOrAction,
                requestBodyBytes: compressor.Decompress(requestFile.CompressedData),
                isCompressed: false, // Already decompressed above
                encryptedAuthJson: authConfig?.EncryptedJson,
                authType: authType,
                cancellationToken: cancellationToken);

            byte[] compressedResponseBytes = compressor.Compress(response.RawResponseBytes);

            var responseEntity = new ServiceResponseFile
            {
                ServiceRequestFileId = link.ServiceRequestFileId,
                FileFormat = response.ContentType?.Contains("xml", StringComparison.OrdinalIgnoreCase) == true
                    ? "XML"
                    : "BINARY",
                Name = $"response-{link.Id}",
                CompressedData = compressedResponseBytes,
                UncompressedSizeBytes = response.RawResponseBytes.Length,
                CompressionAlgorithmType = "GZip",
                IsBaseSnapshot = true,
                DeltaDepth = 0,
                CreatedBy = executedBy
            };
            await executionRepository.SaveResponseFileAsync(responseEntity, cancellationToken);

            // Update the link with execution results
            await executionRepository.UpdateResponseLinkStatusAsync(
                linkId: link.Id,
                status: response.IsSuccess ? "Success" : "Failure",
                httpStatusCode: response.HttpStatusCode,
                httpRequestDurationMs: (int)response.LatencyMs,
                httpContentType: response.ContentType,
                cancellationToken: cancellationToken);

            return response.IsSuccess;
        }
        catch (SoapException ex)
        {
            logger.LogError(ex, "SOAP execution failure on Link ID {LinkId}", link.Id);
            int? statusCode = ex is SoapHttpException httpEx ? (int?)httpEx.HttpStatusCode : null;
            await executionRepository.UpdateResponseLinkStatusAsync(
                linkId: link.Id,
                status: "Failure",
                httpStatusCode: statusCode,
                httpRequestDurationMs: null,
                cancellationToken: cancellationToken);
            return false;
        }
    }
}