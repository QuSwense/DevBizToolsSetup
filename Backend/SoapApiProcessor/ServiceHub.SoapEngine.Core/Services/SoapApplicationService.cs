using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Common;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;
using ServiceHub.SoapEngine.Core.Parsing;
using ServiceHub.SoapEngine.Core.Validation;

namespace ServiceHub.SoapEngine.Core.Services;

public class SoapApplicationService(
    SoapApplicationRepository appRepository,
    SoapWsdlSyncRepository wsdlRepository,
    SoapOperationRepository operationRepository,
    SoapRequestFileRepository requestFileRepository,
    SoapExecutionRepository executionRepository,
    SoapEncryptionService encryptionService,
    SoapVersionGeneratorService versionGenerator,
    WsdlParser wsdlParser,
    SoapFileCompressor compressor,
    SoapFileDeltaPatcher deltaPatcher,
    ILogger<SoapApplicationService> logger,
    // Validators
    IValidator<RegisterApplicationInput> registerValidator,
    IValidator<CreateFullApplicationInput> createFullValidator,
    IValidator<UpdateFullApplicationInput> updateFullValidator,
    IValidator<EditApplicationInput> editValidator,
    IValidator<SyncWsdlInput> syncWsdlValidator,
    IValidator<InspectWsdlInput> inspectWsdlValidator,
    IValidator<UploadRequestFileInput> uploadValidator,
    IValidator<ConfigureAuthInput> configureAuthValidator,
    IValidator<CreateManualOperationInput> manualOpValidator)
{
    // ---------- WSDL Inspection ----------
    public async Task<Result<List<ParsedWsdlOperationDto>>> InspectWsdlOperationsAsync(
        InspectWsdlInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = inspectWsdlValidator.Validate(input);
        if (!validation.IsValid)
            return Result<List<ParsedWsdlOperationDto>>.Failure(string.Join("; ", validation.Errors));

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
                return Result<List<ParsedWsdlOperationDto>>.Failure("Either WsdlUrl or WsdlFileStream must be provided.");
            }

            var parsedMetadata = wsdlParser.ParseContent(wsdlContent);
            var operations = parsedMetadata.Operations.Select(op => new ParsedWsdlOperationDto
            {
                OperationName = op.OperationName,
                SoapAction = op.SoapAction,
                InputRootElementName = op.InputRootElementName,
                OutputRootElementName = op.OutputRootElementName,
                TargetNamespace = op.TargetNamespace
            }).ToList();

            return Result<List<ParsedWsdlOperationDto>>.Success(operations);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error occurred while inspecting WSDL.");
            return Result<List<ParsedWsdlOperationDto>>.Failure($"Failed to parse WSDL: {ex.Message}");
        }
    }

    // ---------- Application CRUD ----------
    public async Task<Result<SoapApplication>> CreateFullApplicationAsync(
        CreateFullApplicationInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = createFullValidator.Validate(input);
        if (!validation.IsValid)
            return Result<SoapApplication>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Creating full SOAP Application: {AppName}", input.AppName);

        var regInput = new RegisterApplicationInput
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
            return Result<SoapApplication>.Failure(appResult.ErrorMessage!);

        var createdApp = appResult.Data!;

        if (input.AuthType.HasValue && input.AuthCredentials is not null)
        {
            var authInput = new ConfigureAuthInput
            {
                AppId = createdApp.Id,
                ConfiguredBy = input.CreatedBy,
                Credentials = input.AuthCredentials
            };
            await ConfigureAuthenticationAsync(authInput, cancellationToken);
        }

        foreach (var opInput in input.Operations)
        {
            var manualInput = new CreateManualOperationInput
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

        return Result<SoapApplication>.Success(createdApp);
    }

    public async Task<Result<bool>> UpdateFullApplicationAsync(
        UpdateFullApplicationInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = updateFullValidator.Validate(input);
        if (!validation.IsValid)
            return Result<bool>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Updating full SOAP Application ID: {AppId}", input.AppId);

        var editInput = new EditApplicationInput
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
            return Result<bool>.Failure(editResult.ErrorMessage!);

        if (input.UpdateAuthentication && input.AuthType.HasValue && input.AuthCredentials is not null)
        {
            var authInput = new ConfigureAuthInput
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
                existingOp.SoapAction = opInput.SoapAction;
                existingOp.InputRootElementName = opInput.InputRootElementName;
                existingOp.OutputRootElementName = opInput.OutputRootElementName;
                existingOp.IsActive = opInput.IsActive;
                existingOp.LastUpdatedAt = DateTime.UtcNow;
                existingOp.LastUpdatedBy = input.UpdatedBy;
                await operationRepository.UpdateAsync(existingOp, cancellationToken);
            }
            else
            {
                var manualInput = new CreateManualOperationInput
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

        return Result<bool>.Success(true);
    }

    // ---------- Sub‑methods ----------
    public async Task<Result<SoapApplication>> RegisterApplicationAsync(
        RegisterApplicationInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = registerValidator.Validate(input);
        if (!validation.IsValid)
            return Result<SoapApplication>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Registering SOAP Application: {AppName}", input.AppName);

        string version = versionGenerator.GenerateNextVersion();
        var app = new SoapApplication
        {
            AppName = input.AppName,
            BaseUrl = input.BaseUrl,
            WsdlRelativeUrl = input.WsdlRelativeUrl,
            HealthcheckRelativeUrl = input.HealthcheckRelativeUrl,
            Description = input.Description,
            Version = version,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = input.CreatedBy
        };

        var registeredApp = await appRepository.AddAsync(app, cancellationToken);

        if (input.DirectWsdlStream is not null)
        {
            var syncInput = new SyncWsdlInput
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
            var syncInput = new SyncWsdlInput
            {
                AppId = registeredApp.Id,
                WsdlUrl = fullWsdlUrl,
                SyncedBy = input.CreatedBy,
                ChangeComment = "Initial WSDL registration from constructed URL."
            };
            await SyncWsdlAsync(syncInput, cancellationToken);
        }

        return Result<SoapApplication>.Success(registeredApp);
    }

    public async Task<Result<bool>> EditApplicationAsync(
        EditApplicationInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = editValidator.Validate(input);
        if (!validation.IsValid)
            return Result<bool>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Editing SOAP Application ID: {AppId}", input.AppId);

        var existingApp = await appRepository.GetByIdAsync(input.AppId, cancellationToken);
        if (existingApp is null)
            return Result<bool>.Failure($"SOAP Application with ID {input.AppId} not found.");

        string nextVersion = versionGenerator.GenerateNextVersion(existingApp.Version);
        existingApp.AppName = input.AppName;
        existingApp.BaseUrl = input.BaseUrl;
        existingApp.WsdlRelativeUrl = input.WsdlRelativeUrl;
        existingApp.HealthcheckRelativeUrl = input.HealthcheckRelativeUrl;
        existingApp.Description = input.Description;
        existingApp.Version = nextVersion;
        existingApp.LastUpdatedAt = DateTime.UtcNow;
        existingApp.LastUpdatedBy = input.UpdatedBy;

        await appRepository.UpdateAsync(existingApp, cancellationToken);
        return Result<bool>.Success(true);
    }

    public async Task<Result<SoapWsdlSync>> SyncWsdlAsync(
        SyncWsdlInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = syncWsdlValidator.Validate(input);
        if (!validation.IsValid)
            return Result<SoapWsdlSync>.Failure(string.Join("; ", validation.Errors));

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
            return Result<SoapWsdlSync>.Failure("Either WsdlFileStream or WsdlUrl must be provided.");
        }

        var parsedMetadata = wsdlParser.ParseContent(wsdlContent);
        string? latestWsdlVersion = await wsdlRepository.GetLatestWsdlVersionAsync(input.AppId, cancellationToken);
        string version = versionGenerator.GenerateNextVersion(latestWsdlVersion);

        var wsdlSync = new SoapWsdlSync
        {
            AppId = input.AppId,
            WsdlUrl = input.WsdlUrl,
            WsdlContent = wsdlContent,
            Version = version,
            SyncedAt = DateTime.UtcNow,
            SyncedBy = input.SyncedBy
        };

        var savedSync = await wsdlRepository.SaveWsdlSyncAsync(wsdlSync, parsedMetadata, input.ChangeComment, cancellationToken);
        return Result<SoapWsdlSync>.Success(savedSync);
    }

    public async Task<Result<SoapRequestFile>> UploadRequestFileStreamAsync(
        UploadRequestFileInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = uploadValidator.Validate(input);
        if (!validation.IsValid)
            return Result<SoapRequestFile>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Uploading Request File {FileName} for Operation ID: {OperationId}", input.FileName, input.OperationId);

        using var memoryStream = new MemoryStream();
        await input.FileStream.CopyToAsync(memoryStream, cancellationToken);
        var newRawBytes = memoryStream.ToArray();
        var compressedNewBytes = compressor.Compress(newRawBytes);

        var existingFile = await requestFileRepository.GetByOperationAndNameAsync(input.OperationId, input.FileName, cancellationToken);

        if (existingFile is null)
        {
            string initialVersion = versionGenerator.GenerateNextVersion();
            var requestFile = new SoapRequestFile
            {
                OperationId = input.OperationId,
                FileName = input.FileName,
                FileData = compressedNewBytes,
                UncompressedSizeBytes = newRawBytes.Length,
                Version = initialVersion,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = input.CreatedBy
            };
            var savedFile = await requestFileRepository.AddAsync(requestFile, cancellationToken);
            return Result<SoapRequestFile>.Success(savedFile);
        }
        else
        {
            string priorVersion = existingFile.Version;
            byte[] oldRawBytes = compressor.Decompress(existingFile.FileData);
            int consecutiveDiffs = await requestFileRepository.GetConsecutiveDiffCountAsync(existingFile.Id, cancellationToken);

            byte[]? compressedBackwardDiff = null;
            byte[]? compressedFullData = null;

            if (consecutiveDiffs < 5)
            {
                compressedBackwardDiff = deltaPatcher.CreateBackwardDiff(newRawBytes, oldRawBytes);
            }
            else
            {
                compressedFullData = compressor.Compress(oldRawBytes);
            }

            string nextVersion = versionGenerator.GenerateNextVersion(priorVersion);
            existingFile.FileData = compressedNewBytes;
            existingFile.UncompressedSizeBytes = newRawBytes.Length;
            existingFile.Version = nextVersion;
            existingFile.LastUpdatedAt = DateTime.UtcNow;
            existingFile.LastUpdatedBy = input.CreatedBy;

            await requestFileRepository.UpdateWithHistoryChainAsync(
                existingFile,
                priorVersion,
                compressedBackwardDiff,
                compressedFullData,
                cancellationToken);

            return Result<SoapRequestFile>.Success(existingFile);
        }
    }

    public async Task<Result<bool>> ConfigureAuthenticationAsync(
        ConfigureAuthInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = configureAuthValidator.Validate(input);
        if (!validation.IsValid)
            return Result<bool>.Failure(string.Join("; ", validation.Errors));

        string encryptedCredentialsJson = encryptionService.EncryptObject(input.Credentials);

        var authEntity = new SoapAppAuthentication
        {
            AppId = input.AppId,
            AuthenticationType = input.Credentials.AuthenticationType.ToString(),
            EncryptedCredentialsJson = encryptedCredentialsJson,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = input.ConfiguredBy
        };

        await appRepository.SaveAuthenticationAsync(authEntity, cancellationToken);
        return Result<bool>.Success(true);
    }

    public async Task<Result<SoapOperation>> CreateManualOperationAsync(
        CreateManualOperationInput input,
        CancellationToken cancellationToken = default)
    {
        var validation = manualOpValidator.Validate(input);
        if (!validation.IsValid)
            return Result<SoapOperation>.Failure(string.Join("; ", validation.Errors));

        logger.LogInformation("Manually adding operation '{OpName}' to App ID: {AppId}", input.OperationName, input.AppId);

        var latestSync = await wsdlRepository.GetLatestByAppIdAsync(input.AppId, cancellationToken);
        int wsdlSyncId;

        if (latestSync is null)
        {
            string version = versionGenerator.GenerateNextVersion();
            var dummySync = new SoapWsdlSync
            {
                AppId = input.AppId,
                WsdlContent = "<manual-operations-container />",
                Version = version,
                SyncedAt = DateTime.UtcNow,
                SyncedBy = input.CreatedBy
            };
            var emptyMetadata = new Parsing.Models.ParsedWsdlMetadata
            {
                RawWsdlContent = dummySync.WsdlContent
            };
            var savedSync = await wsdlRepository.SaveWsdlSyncAsync(
                dummySync,
                emptyMetadata,
                "Container created for manual operations.",
                cancellationToken);
            wsdlSyncId = savedSync.Id;
        }
        else
        {
            wsdlSyncId = latestSync.Id;
        }

        var operation = new SoapOperation
        {
            AppId = input.AppId,
            WsdlSyncId = wsdlSyncId,
            OperationName = input.OperationName,
            Description = input.Description,
            SoapAction = input.SoapAction,
            InputRootElementName = input.InputRootElementName,
            OutputRootElementName = input.OutputRootElementName,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = input.CreatedBy
        };

        var createdOperation = await operationRepository.AddAsync(operation, input.TargetNamespace, input.RawXsdSchema, cancellationToken);
        return Result<SoapOperation>.Success(createdOperation);
    }

    // ---------- Query Methods (Data Retrieval) ----------
    public async Task<PagedResult<SoapApplication>> GetApplicationsAsync(
        ApplicationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await appRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapOperation>> GetOperationsAsync(
        OperationFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await operationRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapRequestFile>> GetRequestFilesAsync(
        RequestFileFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await requestFileRepository.GetPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapExecutionGroup>> GetExecutionGroupsAsync(
        ExecutionGroupFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetGroupsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapExecutionRun>> GetExecutionRunsAsync(
        ExecutionRunFilter filter,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetRunsPagedAsync(filter, cancellationToken);
    }

    public async Task<PagedResult<SoapResponseFile>> GetResponseFilesAsync(
        int? executionItemRunId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        return await executionRepository.GetResponseFilesPagedAsync(executionItemRunId, pageNumber, pageSize, cancellationToken);
    }
}