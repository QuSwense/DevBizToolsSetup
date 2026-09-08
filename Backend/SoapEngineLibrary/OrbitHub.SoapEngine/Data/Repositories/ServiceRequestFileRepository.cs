namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using LinqToDB.Data;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides database access for SOAP request files using the unified ServiceAppDbContext.
/// Uses the delta chain pattern (IsBaseSnapshot/ParentBaseId/ParentDeltaId/DeltaDepth)
/// instead of the legacy separate history table.
/// </summary>
public class ServiceRequestFileRepository(ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Inserts a new request file as a base snapshot (DeltaDepth = 0) in the delta chain.
    /// </summary>
    public async Task<ServiceRequestFile> AddAsync(ServiceRequestFile requestFile, CancellationToken cancellationToken = default)
    {
        requestFile.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
        requestFile.IsBaseSnapshot = true;
        requestFile.DeltaDepth = 0;
        requestFile.CreatedAt = DateTime.UtcNow;
        requestFile.IsActive = true;

        var fileId = await Context.InsertWithInt32IdentityAsync(requestFile, token: cancellationToken);
        requestFile.Id = fileId;
        return requestFile;
    }

    /// <summary>
    /// Updates an existing request file by creating a new delta chain entry.
    /// The previous version is preserved as a delta record (IsBaseSnapshot = false),
    /// and the active record is updated with the new payload.
    /// </summary>
    public async Task<ServiceRequestFile> UpdateWithDeltaChainAsync(
        ServiceRequestFile activeFile,
        byte[]? backwardDiffData,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Find the base snapshot ID for this delta chain
            int baseId = activeFile.ParentBaseId ?? activeFile.Id;

            // 2. Create a delta record preserving the old version
            var deltaRecord = new ServiceRequestFile
            {
                ServiceOperationId = activeFile.ServiceOperationId,
                FileFormat = activeFile.FileFormat,
                Name = activeFile.Name,
                IsBaseSnapshot = false,
                ParentBaseId = baseId,
                ParentDeltaId = activeFile.Id,
                DeltaDepth = activeFile.DeltaDepth + 1,
                CompressedData = backwardDiffData ?? activeFile.CompressedData,
                UncompressedSizeBytes = activeFile.UncompressedSizeBytes,
                CompressionAlgorithmType = backwardDiffData is not null ? null : activeFile.CompressionAlgorithmType,
                ContentHash = activeFile.ContentHash,
                RecordVersion = activeFile.RecordVersion,
                IsActive = false, // Historical record
                CreatedAt = DateTime.UtcNow,
                CreatedBy = activeFile.LastUpdatedBy ?? activeFile.CreatedBy
            };

            await Context.InsertAsync(deltaRecord, token: cancellationToken);

            // 3. Update the active file record with new payload
            activeFile.RecordVersion = await GetNextVersionAsync(activeFile.RecordVersion, cancellationToken);
            activeFile.LastUpdatedAt = DateTime.UtcNow;
            await Context.UpdateAsync(activeFile, token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return activeFile;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Retrieves a request file by its primary key identifier.
    /// </summary>
    public async Task<ServiceRequestFile?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceRequestFiles
            .FirstOrDefaultAsync(f => f.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves all active request files associated with a target operation ID.
    /// </summary>
    public async Task<List<ServiceRequestFile>> GetByOperationIdAsync(int operationId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceRequestFiles
            .Where(f => f.ServiceOperationId == operationId && f.IsActive)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a request file by operation ID and file name.
    /// </summary>
    public async Task<ServiceRequestFile?> GetByOperationAndNameAsync(int operationId, string fileName, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceRequestFiles
            .Where(f => f.ServiceOperationId == operationId && f.Name == fileName && f.IsActive)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Fetches the full delta chain for a given request file (base snapshot + all deltas).
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
    /// Toggles active state for a specific request file.
    /// </summary>
    public async Task UpdateStatusAsync(int fileId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        var nextVersion = await GetNextVersionAsync(null, cancellationToken);
        await Context.ServiceRequestFiles
            .Where(f => f.Id == fileId)
            .Set(f => f.IsActive, isActive)
            .Set(f => f.RecordVersion, nextVersion)
            .Set(f => f.LastUpdatedAt, DateTime.UtcNow)
            .Set(f => f.LastUpdatedBy, updatedBy)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Fetches the latest RecordVersion string for request files under an operation.
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
    /// Gets the count of consecutive delta records since the most recent base snapshot.
    /// </summary>
    public async Task<int> GetConsecutiveDeltaCountAsync(int requestFileId, CancellationToken cancellationToken = default)
    {
        var file = await GetByIdAsync(requestFileId, cancellationToken);
        if (file is null)
            return 0;

        int baseId = file.ParentBaseId ?? file.Id;

        // Count all non-base records in this delta chain
        return await Context.ServiceRequestFiles
            .Where(f => f.ParentBaseId == baseId && !f.IsBaseSnapshot)
            .CountAsync(cancellationToken);
    }

    /// <summary>
    /// Calls the database function dbo.fn_CalculateVersion to compute the next version string.
    /// </summary>
    private async Task<string> GetNextVersionAsync(string? previousVersion, CancellationToken cancellationToken = default)
    {
        var param = previousVersion is not null
            ? new DataParameter("@PreviousVersion", previousVersion)
            : new DataParameter("@PreviousVersion", DBNull.Value);

        var result = await Context.QueryAsync<string>(
            "SELECT dbo.fn_CalculateVersion(@PreviousVersion)", param);

        return result.FirstOrDefault() ?? "00.00.00";
    }

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
            "filename" or "name" => descending ? query.OrderByDescending(f => f.Name) : query.OrderBy(f => f.Name),
            "createdat" => descending ? query.OrderByDescending(f => f.CreatedAt) : query.OrderBy(f => f.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(f => f.CreatedBy) : query.OrderBy(f => f.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(f => f.IsActive) : query.OrderBy(f => f.IsActive),
            "version" or "recordversion" => descending ? query.OrderByDescending(f => f.RecordVersion) : query.OrderBy(f => f.RecordVersion),
            _ => query.OrderBy(f => f.Id)
        };
    }
}