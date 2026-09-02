using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Common;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Exceptions;
using ServiceHub.SoapEngine.Core.Models.Outputs;

namespace ServiceHub.SoapEngine.Core.Services;

public class SoapExecutionGroupRunner(
    SoapExecutionRepository executionRepository,
    SoapApplicationRepository appRepository,
    SoapOperationRepository operationRepository,
    SoapRequestFileRepository requestFileRepository,
    SoapClientService soapClientService,
    SoapFileCompressor compressor,
    SoapVersionGeneratorService versionGenerator,
    ILogger<SoapExecutionGroupRunner> logger)
{
    public async Task<Result<SoapExecutionRun>> RunGroupAsync(
        int groupId,
        string executedBy,
        CancellationToken cancellationToken = default)
    {
        // Validate inputs
        if (groupId <= 0)
            return Result<SoapExecutionRun>.Failure("groupId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(executedBy))
            return Result<SoapExecutionRun>.Failure("executedBy is required.");

        logger.LogInformation("Initiating batch execution run for Execution Group ID: {GroupId} by {ExecutedBy}", groupId, executedBy);

        var group = await executionRepository.GetGroupByIdAsync(groupId, cancellationToken);
        if (group is null)
            return Result<SoapExecutionRun>.Failure($"Execution group with ID {groupId} was not found.");

        var groupItems = await executionRepository.GetGroupItemsAsync(groupId, cancellationToken);
        if (groupItems.Count == 0)
            return Result<SoapExecutionRun>.Failure($"Execution group {groupId} contains no registered group items.");

        var run = await executionRepository.StartExecutionRunAsync(groupId, executedBy, cancellationToken);
        bool hasFailures = false;

        try
        {
            foreach (var item in groupItems)
            {
                if (cancellationToken.IsCancellationRequested)
                {
                    logger.LogWarning("Execution run ID {RunId} cancelled by caller.", run.Id);
                    await executionRepository.CompleteExecutionRunAsync(run.Id, EExecutionStatus.Cancelled, cancellationToken);
                    return Result<SoapExecutionRun>.Failure("Execution run was cancelled.");
                }

                bool itemSuccess = await ExecuteItemAsync(run.Id, item, executedBy, cancellationToken);
                if (!itemSuccess)
                    hasFailures = true;
            }

            var finalStatus = hasFailures ? EExecutionStatus.Failed : EExecutionStatus.Completed;
            await executionRepository.CompleteExecutionRunAsync(run.Id, finalStatus, cancellationToken);
            run.RunStatus = finalStatus.ToDbString();
            run.CompletedAt = DateTime.UtcNow;
            return Result<SoapExecutionRun>.Success(run);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled failure during execution run ID {RunId}", run.Id);
            await executionRepository.CompleteExecutionRunAsync(run.Id, EExecutionStatus.Failed, cancellationToken);
            return Result<SoapExecutionRun>.Failure($"Execution run failed: {ex.Message}");
        }
    }

    private async Task<bool> ExecuteItemAsync(
        int runId,
        SoapExecutionGroupItem item,
        string executedBy,
        CancellationToken cancellationToken)
    {
        logger.LogInformation("Executing Group Item ID: {GroupItemId} (Request File ID: {RequestFileId}) in Run ID: {RunId}", item.Id, item.RequestFileId, runId);

        var requestFile = await requestFileRepository.GetByIdAsync(item.RequestFileId, cancellationToken);
        if (requestFile is null || !requestFile.IsActive)
        {
            logger.LogError("Request file ID {RequestFileId} is inactive or missing.", item.RequestFileId);
            return false;
        }

        var operation = await operationRepository.GetByIdAsync(requestFile.OperationId, cancellationToken);
        if (operation is null)
        {
            logger.LogError("Parent Operation ID {OperationId} missing for Request File {RequestFileId}.", requestFile.OperationId, item.RequestFileId);
            return false;
        }

        var application = await appRepository.GetByIdAsync(operation.AppId, cancellationToken);
        if (application is null || !application.IsActive)
        {
            logger.LogError("Parent Application ID {AppId} missing or inactive.", operation.AppId);
            return false;
        }

        var authConfig = await appRepository.GetAuthenticationByAppIdAsync(application.Id, cancellationToken);
        EAuthenticationType? authType = null;
        if (authConfig is not null && Enum.TryParse<EAuthenticationType>(authConfig.AuthenticationType, out var parsedAuthType))
            authType = parsedAuthType;

        var itemRun = new SoapExecutionItemRun
        {
            ExecutionRunId = runId,
            ExecutionGroupItemId = item.Id,
            ItemExecutionStatus = EItemExecutionStatus.InProgress.ToDbString(),
            ExecutedAt = DateTime.UtcNow
        };
        itemRun = await executionRepository.AddItemRunAsync(itemRun, cancellationToken);

        try
        {
            SoapExecutionResponse response = await soapClientService.ExecuteAsync(
                targetUrl: application.BaseUrl,
                soapAction: operation.SoapAction,
                requestBodyBytes: requestFile.FileData,
                isCompressed: true,
                encryptedAuthJson: authConfig?.EncryptedCredentialsJson,
                authType: authType,
                cancellationToken: cancellationToken);

            byte[] compressedResponseBytes = compressor.Compress(response.RawResponseBytes);
            string responseVersion = versionGenerator.GenerateNextVersion();

            var responseEntity = new SoapResponseFile
            {
                ExecutionItemRunId = itemRun.Id,
                ResponseFormat = response.ContentType?.Contains("xml", StringComparison.OrdinalIgnoreCase) == true
                    ? EResponseFormat.XML.ToDbString()
                    : EResponseFormat.BINARY.ToDbString(),
                FileData = compressedResponseBytes,
                UncompressedSizeBytes = response.RawResponseBytes.Length,
                Version = responseVersion,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = executedBy
            };
            await executionRepository.SaveResponseFileAsync(responseEntity, embeddings: null, cancellationToken);

            var itemStatus = response.IsSuccess ? EItemExecutionStatus.Success : EItemExecutionStatus.Failure;
            await executionRepository.UpdateItemRunStatusAsync(
                itemRunId: itemRun.Id,
                status: itemStatus,
                httpStatusCode: response.HttpStatusCode,
                executionTimeMs: (int)response.LatencyMs,
                cancellationToken: cancellationToken);

            return response.IsSuccess;
        }
        catch (SoapException ex)
        {
            logger.LogError(ex, "SOAP execution failure on Item Run ID {ItemRunId}", itemRun.Id);
            int? statusCode = ex is SoapHttpException httpEx ? (int?)httpEx.HttpStatusCode : null;
            await executionRepository.UpdateItemRunStatusAsync(
                itemRunId: itemRun.Id,
                status: EItemExecutionStatus.Failure,
                httpStatusCode: statusCode,
                executionTimeMs: null,
                cancellationToken: cancellationToken);
            return false;
        }
    }
}