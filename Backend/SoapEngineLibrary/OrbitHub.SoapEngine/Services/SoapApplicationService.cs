using Microsoft.Extensions.Logging;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.GenericModels.Enums;
using OrbitHub.GenericModels.Models;
using OrbitHub.SoapEngine.Core.Data.Repositories;
using OrbitHub.SoapEngine.Core.Models.Inputs;
using OrbitHub.SoapEngine.Core.Models.Inputs.Filters;
using OrbitHub.SoapEngine.Core.Parsing;
using OrbitHub.SoapEngine.Core.Validation;

namespace OrbitHub.SoapEngine.Core.Services;

public class SoapApplicationService(
    ServiceApplicationRepository appRepository,
    ServiceDefinitionSyncRepository definitionSyncRepository,
    ServiceOperationRepository operationRepository,
    ServiceRequestFileRepository requestFileRepository,
    ServiceExecutionAuditRepository executionRepository,
    SoapEncryptionService encryptionService,
    WsdlParser wsdlParser,
    SoapFileCompressor compressor,
    SoapFileDeltaPatcher deltaPatcher,
    ILogger<SoapApplicationService> logger,
    // Validators
    IValidator<RegisterApplicationInputModel> registerValidator,
    IValidator<CreateFullApplicationInputModel> createFullValidator,
    IValidator<UpdateFullApplicationInputModel> updateFullValidator,
    IValidator<EditApplicationInputModel> editValidator,
    IValidator<SyncWsdlInputModel> syncWsdlValidator,
    IValidator<InspectWsdlInputModel> inspectWsdlValidator,
    IValidator<UploadRequestFileInputModel> uploadValidator,
    IValidator<ConfigureAuthInputModel> configureAuthValidator,
    IValidator<CreateManualOperationInputModel> manualOpValidator)
{
    public async Task<ResultModel<List<ParsedWsdlOperationDtoInputModel>>> InspectWsdlOperationsAsync(
        InspectWsdlInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = inspectWsdlValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<List<ParsedWsdlOperationDtoInputModel>>.Failure(string.Join("; ", validation.Errors));

        try
        {
            string wsdlContent;
            if (input.WsdlFileStream is not null)
            {
                using var reader = new StreamReader(input.WsdlFileStream, leaveOpen: true);
                wsdlContent = await reader.ReadToEndAsync(cancellationToken);
            }
            else if (!string.IsNullOrWhiteSpace(input.WsdlUrl))
            {
                var metadataFromUrl = await wsdlParser.FetchAndParseAsync(input.WsdlUrl, cancellationToken);
                wsdlContent = metadataFromUrl.RawWsdlContent;
            }
            else
            {
                return ResultModel<List<ParsedWsdlOperationDtoInputModel>>.Failure("Either WsdlUrl or WsdlFileStream must be provided.");
            }

            var parsedMetadata = wsdlParser.ParseContent(wsdlContent);
            var operations = parsedMetadata.Operations.Select(op => new ParsedWsdlOperationDtoInputModel
            {
                OperationName = op.OperationName,
                SoapAction = op.SoapAction,
                InputRootElementName = op.InputRootElementName,
                OutputRootElementName = op.OutputRootElementName,
                TargetNamespace = op.TargetNamespace
            }).ToList();

            return ResultModel<List<ParsedWsdlOperationDtoInputModel>>.Success(operations);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error occurred while inspecting WSDL.");
            return ResultModel<List<ParsedWsdlOperationDtoInputModel>>.Failure($"Failed to parse WSDL: {ex.Message}");
        }
    }

    // ---------- Application CRUD ----------
    public async Task<ResultModel<ServiceApplication>> CreateFullApplicationAsync(
        CreateFullApplicationInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = createFullValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<ServiceApplication>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Creating full SOAP Application: {AppName}", input.AppName);

        var regInput = new RegisterApplicationInputModel
        {
            AppName = input.AppName,
            BaseUrl = input.BaseUrl,
            WsdlRelativeUrl = input.WsdlRelativeUrl,
            HealthcheckRelativeUrl = input.HealthcheckRelativeUrl,
            Description = input.Description,
            CreatedBy = input.CreatedBy,
            DirectWsdlStream = input.DirectWsdlStream
        };

        var appResult = await RegisterApplicationAsync(regInput, cancellationToken);
        if (!appResult.IsSuccess)
            return ResultModel<ServiceApplication>.Failure(appResult.ErrorMessage!);

        var createdApp = appResult.Data!;

        if (input.AuthType.HasValue && input.AuthCredentials is not null)
        {
            var authInput = new ConfigureAuthInputModel
            {
                AppId = createdApp.Id,
                ConfiguredBy = input.CreatedBy,
                Credentials = input.AuthCredentials
            };
            await ConfigureAuthenticationAsync(authInput, cancellationToken);
        }

        foreach (var opInput in input.Operations)
        {
            var manualInput = new CreateManualOperationInputModel
            {
                AppId = createdApp.Id,
                OperationName = opInput.OperationName,
                Description = opInput.Description,
                SoapAction = opInput.SoapAction,
                InputRootElementName = opInput.InputRootElementName ?? opInput.OperationName,
                OutputRootElementName = opInput.OutputRootElementName ?? $"{opInput.OperationName}Response",
                TargetNamespace = opInput.TargetNamespace ?? "http://tempuri.org/",
                RawXsdSchema = opInput.RawXsdSchema,
                CreatedBy = input.CreatedBy
            };
            await CreateManualOperationAsync(manualInput, cancellationToken);
        }

        return ResultModel<ServiceApplication>.Success(createdApp);
    }

    public async Task<ResultModel<bool>> UpdateFullApplicationAsync(
        UpdateFullApplicationInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = updateFullValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<bool>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Updating full SOAP Application ID: {AppId}", input.AppId);

        var editInput = new EditApplicationInputModel
        {
            AppId = input.AppId,
            AppName = input.AppName,
            BaseUrl = input.BaseUrl,
            WsdlRelativeUrl = input.WsdlRelativeUrl,
            HealthcheckRelativeUrl = input.HealthcheckRelativeUrl,
            Description = input.Description,
            UpdatedBy = input.UpdatedBy
        };
        var editResult = await EditApplicationAsync(editInput, cancellationToken);
        if (!editResult.IsSuccess)
            return ResultModel<bool>.Failure(editResult.ErrorMessage!);

        if (input.UpdateAuthentication && input.AuthType.HasValue && input.AuthCredentials is not null)
        {
            var authInput = new ConfigureAuthInputModel
            {
                AppId = input.AppId,
                ConfiguredBy = input.UpdatedBy,
                Credentials = input.AuthCredentials
            };
            await ConfigureAuthenticationAsync(authInput, cancellationToken);
        }

        var existingOperations = await operationRepository.GetByAppIdAsync(input.AppId, cancellationToken);
        var existingDict = existingOperations.ToDictionary(op => op.OperationName, StringComparer.OrdinalIgnoreCase);

        foreach (var opInput in input.Operations)
        {
            if (existingDict.TryGetValue(opInput.OperationName, out var existingOp))
            {
                existingOp.Description = opInput.Description;
                existingOp.EndpointOrAction = opInput.SoapAction;
                existingOp.IsActive = opInput.IsActive;
                existingOp.LastUpdatedAt = DateTime.UtcNow;
                existingOp.LastUpdatedBy = input.UpdatedBy;
                await operationRepository.UpdateAsync(existingOp, cancellationToken);
            }
            else
            {
                var manualInput = new CreateManualOperationInputModel
                {
                    AppId = input.AppId,
                    OperationName = opInput.OperationName,
                    Description = opInput.Description,
                    SoapAction = opInput.SoapAction,
                    InputRootElementName = opInput.InputRootElementName ?? opInput.OperationName,
                    OutputRootElementName = opInput.OutputRootElementName ?? $"{opInput.OperationName}Response",
                    TargetNamespace = opInput.TargetNamespace ?? "http://tempuri.org/",
                    RawXsdSchema = opInput.RawXsdSchema,
                    CreatedBy = input.UpdatedBy
                };
                await CreateManualOperationAsync(manualInput, cancellationToken);
            }
        }

        return ResultModel<bool>.Success(true);
    }

    // ---------- Sub‑methods ----------
    public async Task<ResultModel<ServiceApplication>> RegisterApplicationAsync(
        RegisterApplicationInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = registerValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<ServiceApplication>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Registering SOAP Application: {AppName}", input.AppName);

        var app = new ServiceApplication
        {
            Name = input.AppName,
            BaseUrl = input.BaseUrl,
            DefinitionRelativeUrl = input.WsdlRelativeUrl,
            HealthcheckRelativeUrl = input.HealthcheckRelativeUrl,
            Description = input.Description,
            ServiceType = "SOAP",
            DefinitionType = "WSDL",
            IsActive = true,
            CreatedBy = input.CreatedBy
        };

        var registeredApp = await appRepository.AddAsync(app, cancellationToken);

        if (input.DirectWsdlStream is not null)
        {
            var syncInput = new SyncWsdlInputModel
            {
                AppId = registeredApp.Id,
                WsdlFileStream = input.DirectWsdlStream,
                SyncedBy = input.CreatedBy,
                ChangeComment = "Initial WSDL registration from direct stream."
            };
            await SyncWsdlAsync(syncInput, cancellationToken);
        }
        else if (!string.IsNullOrWhiteSpace(input.WsdlRelativeUrl))
        {
            var fullWsdlUrl = new Uri(new Uri(input.BaseUrl), input.WsdlRelativeUrl).ToString();
            var syncInput = new SyncWsdlInputModel
            {
                AppId = registeredApp.Id,
                WsdlUrl = fullWsdlUrl,
                SyncedBy = input.CreatedBy,
                ChangeComment = "Initial WSDL registration from constructed URL."
            };
            await SyncWsdlAsync(syncInput, cancellationToken);
        }

        return ResultModel<ServiceApplication>.Success(registeredApp);
    }

    public async Task<ResultModel<bool>> EditApplicationAsync(
        EditApplicationInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = editValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<bool>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Editing SOAP Application ID: {AppId}", input.AppId);

        var existingApp = await appRepository.GetByIdAsync(input.AppId, cancellationToken);
        if (existingApp is null)
            return ResultModel<bool>.Failure($"SOAP Application with ID {input.AppId} not found.");

        existingApp.Name = input.AppName;
        existingApp.BaseUrl = input.BaseUrl;
        existingApp.DefinitionRelativeUrl = input.WsdlRelativeUrl;
        existingApp.HealthcheckRelativeUrl = input.HealthcheckRelativeUrl;
        existingApp.Description = input.Description;
        existingApp.LastUpdatedAt = DateTime.UtcNow;
        existingApp.LastUpdatedBy = input.UpdatedBy;

        await appRepository.UpdateAsync(existingApp, cancellationToken);
        return ResultModel<bool>.Success(true);
    }

    public async Task<ResultModel<ServiceDefinitionSync>> SyncWsdlAsync(
        SyncWsdlInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = syncWsdlValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<ServiceDefinitionSync>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Syncing WSDL for Application ID: {AppId}", input.AppId);

        string wsdlContent;
        if (input.WsdlFileStream is not null)
        {
            using var reader = new StreamReader(input.WsdlFileStream);
            wsdlContent = await reader.ReadToEndAsync(cancellationToken);
        }
        else if (!string.IsNullOrWhiteSpace(input.WsdlUrl))
        {
            var metadataFromUrl = await wsdlParser.FetchAndParseAsync(input.WsdlUrl, cancellationToken);
            wsdlContent = metadataFromUrl.RawWsdlContent;
        }
        else
        {
            return ResultModel<ServiceDefinitionSync>.Failure("Either WsdlFileStream or WsdlUrl must be provided.");
        }

        var parsedMetadata = wsdlParser.ParseContent(wsdlContent);
        string? latestVersion = await definitionSyncRepository.GetLatestVersionAsync(input.AppId, cancellationToken);

        var wsdlBytes = System.Text.Encoding.UTF8.GetBytes(wsdlContent);
        var compressedContent = compressor.Compress(wsdlBytes);

        var definitionSync = new ServiceDefinitionSync
        {
            ServiceApplicationId = input.AppId,
            DefinitionUrl = input.WsdlUrl,
            CompressedContent = compressedContent,
            UncompressedSizeBytes = wsdlBytes.Length,
            CompressionAlgorithmType = "GZip",
            CreatedBy = input.SyncedBy
        };

        var savedSync = await definitionSyncRepository.SaveDefinitionSyncAsync(definitionSync, parsedMetadata, input.ChangeComment, cancellationToken);
        return ResultModel<ServiceDefinitionSync>.Success(savedSync);
    }

    public async Task<ResultModel<ServiceRequestFile>> UploadRequestFileStreamAsync(
        UploadRequestFileInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = uploadValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<ServiceRequestFile>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Uploading Request File {FileName} for Operation ID: {OperationId}", input.FileName, input.OperationId);

        using var memoryStream = new MemoryStream();
        await input.FileStream.CopyToAsync(memoryStream, cancellationToken);
        var newRawBytes = memoryStream.ToArray();
        var compressedNewBytes = compressor.Compress(newRawBytes);

        var existingFile = await requestFileRepository.GetByOperationAndNameAsync(input.OperationId, input.FileName, cancellationToken);

        if (existingFile is null)
        {
            var requestFile = new ServiceRequestFile
            {
                ServiceOperationId = input.OperationId,
                Name = input.FileName,
                FileFormat = EnumHelper<EFileFormat>.GetName(EFileFormat.XML),
                CompressedData = compressedNewBytes,
                UncompressedSizeBytes = newRawBytes.Length,
                CompressionAlgorithmType = EnumHelper<ECompressionAlgorithm>.GetName(ECompressionAlgorithm.Gzip),
                IsBaseSnapshot = true,
                DeltaDepth = 0,
                CreatedBy = input.CreatedBy
            };
            var savedFile = await requestFileRepository.AddAsync(requestFile, cancellationToken);
            return ResultModel<ServiceRequestFile>.Success(savedFile);
        }
        else
        {
            byte[] oldRawBytes = compressor.Decompress(existingFile.CompressedData);
            int consecutiveDeltas = await requestFileRepository.GetConsecutiveDeltaCountAsync(existingFile.Id, cancellationToken);

            byte[]? backwardDiffData = null;

            if (consecutiveDeltas < 5)
            {
                backwardDiffData = deltaPatcher.CreateBackwardDiff(newRawBytes, oldRawBytes);
            }

            existingFile.CompressedData = compressedNewBytes;
            existingFile.UncompressedSizeBytes = newRawBytes.Length;
            existingFile.LastUpdatedAt = DateTime.UtcNow;
            existingFile.LastUpdatedBy = input.CreatedBy;

            await requestFileRepository.UpdateWithDeltaChainAsync(
                existingFile,
                backwardDiffData,
                cancellationToken);

            return ResultModel<ServiceRequestFile>.Success(existingFile);
        }
    }

    public async Task<ResultModel<bool>> ConfigureAuthenticationAsync(
        ConfigureAuthInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = configureAuthValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<bool>.Failure(string.Join("; ", validation.Errors));

        string encryptedCredentialsJson = encryptionService.EncryptObject(input.Credentials);

        var authEntity = new ServiceAppAuthentication
        {
            Name = $"SOAP-Auth-{input.AppId}",
            AuthenticationType = input.Credentials.AuthenticationType.ToString(),
            EncryptionAlgorithmType = "AES-256-GCM",
            EncryptedJson = encryptedCredentialsJson,
            CreatedBy = input.ConfiguredBy
        };

        await appRepository.SaveAuthenticationAsync(authEntity, input.AppId, cancellationToken);
        return ResultModel<bool>.Success(true);
    }

    public async Task<ResultModel<ServiceOperation>> CreateManualOperationAsync(
        CreateManualOperationInputModel input,
        CancellationToken cancellationToken = default)
    {
        var validation = manualOpValidator.Validate(input);
        if (!validation.IsValid)
            return ResultModel<ServiceOperation>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Manually adding operation '{OpName}' to App ID: {AppId}", input.OperationName, input.AppId);

        var operation = new ServiceOperation
        {
            ServiceApplicationId = input.AppId,
            OperationName = input.OperationName,
            Description = input.Description,
            EndpointOrAction = input.SoapAction,
            IsActive = true,
            CreatedBy = input.CreatedBy
        };

        var createdOperation = await operationRepository.AddAsync(
            operation,
            inputRootElementName: input.InputRootElementName,
            outputRootElementName: input.OutputRootElementName,
            targetNamespace: input.TargetNamespace,
            rawXsdSchema: input.RawXsdSchema,
            cancellationToken: cancellationToken);

        return ResultModel<ServiceOperation>.Success(createdOperation);
    }

    public async Task<PagedResultModel<ServiceApplication>> GetApplicationsAsync(
        ApplicationFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await appRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceOperation>> GetOperationsAsync(
        OperationFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await operationRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceRequestFile>> GetRequestFilesAsync(
        RequestFileFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await requestFileRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<DirectExecutionAudit>> GetExecutionAuditsAsync(
        ExecutionAuditFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetAuditsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<DirectExecutionAuditResponseFileLink>> GetExecutionLinksAsync(
        ExecutionAuditLinkFilterModel filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseLinksPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResultModel<ServiceResponseFile>> GetResponseFilesAsync(
        int? serviceRequestFileId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseFilesPagedAsync(serviceRequestFileId, pageNumber, pageSize, cancellationToken);
    }
}