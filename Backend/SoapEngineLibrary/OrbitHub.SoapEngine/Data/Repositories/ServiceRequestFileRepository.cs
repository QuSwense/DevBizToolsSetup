namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.Repositories.TestManagement.Repositories;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides database access for SOAP request files using stored procedure repositories
/// from OrbitHub.Data. Uses the delta chain pattern (IsBaseSnapshot/ParentBaseId/ParentDeltaId/DeltaDepth).
/// Paged/read queries use direct linq2db (hybrid approach).
/// </summary>
public class ServiceRequestFileRepository(
    InsertServiceRequestFileRepository insertFileRepo,
    UpdateServiceRequestFileRepository updateFileRepo,
    UpdateServiceRequestFileWithDeltaChainRepository updateDeltaChainRepo,
    GetServiceRequestFileByIdRepository getByIdRepo,
    GetServiceRequestFileByOperationAndNameRepository getByOpAndNameRepo,
    GetServiceRequestFileConsecutiveDeltaCountRepository getDeltaCountRepo,
    InsertServiceRequestFileEmbeddingRepository insertEmbeddingRepo,
    IUnitOfWork unitOfWork,
    ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Inserts a new request file as a base snapshot via usp_InsertServiceRequestFile SP.
    /// </summary>
    public async Task<ServiceRequestFile> AddAsync(ServiceRequestFile requestFile, CancellationToken cancellationToken = default)
    {
        var result = await insertFileRepo.ExecuteAsync(new InsertServiceRequestFileInput
        {
            ServiceOperationId = requestFile.ServiceOperationId,
            Name = requestFile.Name,
            FileFormat = requestFile.FileFormat,
            IsBaseSnapshot = true,
            ParentBaseId = null,
            ParentDeltaId = null,
            CompressedData = requestFile.CompressedData,
            UncompressedSizeBytes = requestFile.UncompressedSizeBytes,
            CompressionAlgorithmType = requestFile.CompressionAlgorithmType,
            ContentHash = requestFile.ContentHash,
            UserId = requestFile.CreatedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to insert request file: {result.ErrorMessage}");

        var dto = result.Data;
        return new ServiceRequestFile
        {
            Id = dto.FileId ?? throw new InvalidOperationException("SP did not return a FileId."),
            ServiceOperationId = dto.ServiceOperationId ?? throw new InvalidOperationException("SP did not return a ServiceOperationId."),
            FileFormat = dto.FileFormat,
            Name = dto.Name ?? string.Empty,
            IsBaseSnapshot = dto.IsBaseSnapshot ?? true,
            ParentBaseId = dto.ParentBaseId,
            ParentDeltaId = dto.ParentDeltaId,
            DeltaDepth = dto.DeltaDepth ?? 0,
            CompressedData = dto.CompressedData ?? requestFile.CompressedData,
            UncompressedSizeBytes = dto.UncompressedSizeBytes,
            CompressionAlgorithmType = dto.CompressionAlgorithmType,
            ContentHash = dto.ContentHash,
            RecordVersion = dto.RecordVersion ?? "00.00.00",
            IsActive = true,
            CreatedAt = dto.CreatedAt ?? DateTime.UtcNow,
            CreatedBy = dto.CreatedBy ?? requestFile.CreatedBy
        };
    }

    /// <summary>
    /// Updates an existing request file via usp_UpdateServiceRequestFileWithDeltaChain SP.
    /// </summary>
    public async Task<ServiceRequestFile> UpdateWithDeltaChainAsync(
        ServiceRequestFile activeFile,
        byte[]? backwardDiffData,
        CancellationToken cancellationToken = default)
    {
        var result = await updateDeltaChainRepo.ExecuteAsync(new UpdateServiceRequestFileWithDeltaChainInput
        {
            FileId = activeFile.Id,
            CompressedData = activeFile.CompressedData,
            UncompressedSizeBytes = activeFile.UncompressedSizeBytes,
            CompressionAlgorithmType = activeFile.CompressionAlgorithmType,
            ContentHash = activeFile.ContentHash,
            BackwardDiffData = backwardDiffData,
            UserId = activeFile.LastUpdatedBy ?? activeFile.CreatedBy
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update request file with delta chain: {result.ErrorMessage}");

        return activeFile;
    }

    /// <summary>
    /// Retrieves a request file by its primary key identifier via SP.
    /// </summary>
    public async Task<ServiceRequestFile?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await getByIdRepo.ExecuteAsync(
            new GetServiceRequestFileByIdInput { Id = id }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        return MapToEntity(result.Data);
    }

    /// <summary>
    /// Retrieves all active request files associated with a target operation ID via direct query.
    /// </summary>
    public async Task<List<ServiceRequestFile>> GetByOperationIdAsync(int operationId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceRequestFiles
            .Where(f => f.ServiceOperationId == operationId && f.IsActive)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a request file by operation ID and file name via SP.
    /// </summary>
    public async Task<ServiceRequestFile?> GetByOperationAndNameAsync(int operationId, string fileName, CancellationToken cancellationToken = default)
    {
        var result = await getByOpAndNameRepo.ExecuteAsync(
            new GetServiceRequestFileByOperationAndNameInput
            {
                ServiceOperationId = operationId,
                Name = fileName
            }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        return MapToEntity(result.Data);
    }

    /// <summary>
    /// Fetches the full delta chain for a given request file via direct query.
    /// </summary>
    public async Task<List<ServiceRequestFile>> GetDeltaChainAsync(int requestFileId, CancellationToken cancellationToken = default)
    {
        var file = await GetByIdAsync(requestFileId, cancellationToken);
        if (file is null)
            return [];

        int baseId = file.ParentBaseId ?? file.Id;

        return await Context.ServiceRequestFiles
            .Where(f => f.Id == baseId || f.ParentBaseId == baseId)
            .OrderBy(f => f.DeltaDepth)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Toggles active state for a specific request file via UpdateServiceRequestFile SP.
    /// </summary>
    public async Task UpdateStatusAsync(int fileId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        var result = await updateFileRepo.ExecuteAsync(new UpdateServiceRequestFileInput
        {
            FileId = fileId,
            IsActive = isActive,
            UserId = updatedBy
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update request file status: {result.ErrorMessage}");
    }

    /// <summary>
    /// Fetches the latest RecordVersion string for request files under an operation via direct query.
    /// </summary>
    public async Task<string?> GetLatestFileVersionAsync(int operationId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceRequestFiles
            .Where(f => f.ServiceOperationId == operationId)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => f.RecordVersion)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Gets the count of consecutive delta records since the most recent base snapshot via SP.
    /// </summary>
    public async Task<int> GetConsecutiveDeltaCountAsync(int requestFileId, CancellationToken cancellationToken = default)
    {
        var result = await getDeltaCountRepo.ExecuteAsync(
            new GetServiceRequestFileConsecutiveDeltaCountInput { RequestFileId = requestFileId }, cancellationToken);

        if (!result.Success || result.Data is null)
            return 0;

        return result.Data.DeltaCount;
    }

    /// <summary>
    /// Paged query using direct linq2db (hybrid approach).
    /// </summary>
    public async Task<PagedResult<ServiceRequestFile>> GetPagedAsync(
        RequestFileFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.ServiceRequestFiles.AsQueryable();

        if (filter.OperationId.HasValue)
            query = query.Where(f => f.ServiceOperationId == filter.OperationId.Value);
        if (!string.IsNullOrWhiteSpace(filter.FileName))
            query = query.Where(f => f.Name.Contains(filter.FileName));
        if (filter.IsActive.HasValue)
            query = query.Where(f => f.IsActive == filter.IsActive.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplySorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<ServiceRequestFile>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<ServiceRequestFile> ApplySorting(IQueryable<ServiceRequestFile> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(f => f.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "name" => descending ? query.OrderByDescending(f => f.Name) : query.OrderBy(f => f.Name),
            "createdat" => descending ? query.OrderByDescending(f => f.CreatedAt) : query.OrderBy(f => f.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(f => f.CreatedBy) : query.OrderBy(f => f.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(f => f.IsActive) : query.OrderBy(f => f.IsActive),
            _ => query.OrderBy(f => f.Id)
        };
    }

    private static ServiceRequestFile MapToEntity(GetServiceRequestFileByIdOutput dto)
    {
        return new ServiceRequestFile
        {
            Id = dto.Id,
            ServiceOperationId = dto.ServiceOperationId,
            FileFormat = dto.FileFormat,
            Name = dto.Name,
            IsBaseSnapshot = dto.IsBaseSnapshot,
            ParentBaseId = dto.ParentBaseId,
            ParentDeltaId = dto.ParentDeltaId,
            DeltaDepth = dto.DeltaDepth,
            CompressedData = dto.CompressedData,
            UncompressedSizeBytes = dto.UncompressedSizeBytes,
            CompressionAlgorithmType = dto.CompressionAlgorithmType,
            ContentHash = dto.ContentHash,
            RecordVersion = dto.RecordVersion.ToString(),
            IsActive = dto.IsActive,
            CreatedAt = dto.CreatedAt,
            CreatedBy = dto.CreatedBy,
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }
}