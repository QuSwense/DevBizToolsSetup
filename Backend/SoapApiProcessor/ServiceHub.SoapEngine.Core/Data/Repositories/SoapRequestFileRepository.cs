namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides database access and atomic persistence operations for SOAP request files 
/// and historical payload versions using LINQ to DB.
/// </summary>
public class SoapRequestFileRepository(SoapEngineDataContext context)
{
    private SoapEngineDataContext Context { get; } = context;

    /// <summary>
    /// Inserts a new request file into <see cref="SoapRequestFile"/> and creates an initial entry 
    /// in <see cref="SoapRequestFileHistory"/>.
    /// </summary>
    public async Task<SoapRequestFile> AddAsync(SoapRequestFile requestFile, CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Insert active request file record
            var fileId = await Context.InsertWithInt32IdentityAsync(requestFile, token: cancellationToken);
            requestFile.Id = fileId;

            // 2. Insert initial version into history table
            var historyRecord = new SoapRequestFileHistory
            {
                RequestFileId = fileId,
                Version = requestFile.Version,
                FileData = requestFile.FileData,
                DiffData = null, // Initial baseline version has full payload data, no diff
                UncompressedSizeBytes = requestFile.UncompressedSizeBytes,
                FileHash = requestFile.FileHash,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = requestFile.CreatedBy
            };

            await Context.InsertAsync(historyRecord, token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return requestFile;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Updates an existing request file record and records a new historical version entry.
    /// </summary>
    public async Task UpdateWithHistoryAsync(
        SoapRequestFile requestFile,
        byte[]? diffData = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            requestFile.LastUpdatedAt = DateTime.UtcNow;

            // 1. Update the primary active file record
            await Context.UpdateAsync(requestFile, token: cancellationToken);

            // 2. Insert new audit version in history
            var historyRecord = new SoapRequestFileHistory
            {
                RequestFileId = requestFile.Id,
                Version = requestFile.Version,
                FileData = diffData is null ? requestFile.FileData : null, // Store full data if no diff, else store diff
                DiffData = diffData,
                UncompressedSizeBytes = requestFile.UncompressedSizeBytes,
                FileHash = requestFile.FileHash,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = requestFile.LastUpdatedBy ?? requestFile.CreatedBy
            };

            await Context.InsertAsync(historyRecord, token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
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
    public async Task<SoapRequestFile?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.SoapRequestFiles
            .FirstOrDefaultAsync(f => f.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves all active request files associated with a target operation ID.
    /// </summary>
    public async Task<List<SoapRequestFile>> GetByOperationIdAsync(int operationId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapRequestFiles
            .Where(f => f.OperationId == operationId && f.IsActive)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Fetches all version history audit records for a given request file ID.
    /// </summary>
    public async Task<List<SoapRequestFileHistory>> GetHistoryByFileIdAsync(int requestFileId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapRequestFileHistories
            .Where(h => h.RequestFileId == requestFileId)
            .OrderByDescending(h => h.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Toggles active state for a specific request file.
    /// </summary>
    public async Task UpdateStatusAsync(int fileId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        await Context.SoapRequestFiles
            .Where(f => f.Id == fileId)
            .Set(f => f.IsActive, isActive)
            .Set(f => f.LastUpdatedAt, DateTime.UtcNow)
            .Set(f => f.LastUpdatedBy, updatedBy)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Fetches the latest version string for request files under an operation.
    /// </summary>
    public async Task<string?> GetLatestFileVersionAsync(int operationId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapRequestFiles
            .Where(f => f.OperationId == operationId)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => f.Version)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Updates the active request file record with the latest full payload, while recording
    /// a backward diff entry in history for the replaced version.
    /// </summary>
    public async Task UpdateWithBackwardDiffAsync(
        SoapRequestFile activeFile,
        byte[] compressedBackwardDiff,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Insert history entry for the prior version containing the backward diff
            var historyRecord = new SoapRequestFileHistory
            {
                RequestFileId = activeFile.Id,
                Version = activeFile.Version,
                FileData = null, // Old version full binary is replaced by DiffData
                DiffData = compressedBackwardDiff,
                UncompressedSizeBytes = activeFile.UncompressedSizeBytes,
                FileHash = activeFile.FileHash,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = activeFile.LastUpdatedBy ?? activeFile.CreatedBy
            };

            await Context.InsertAsync(historyRecord, token: cancellationToken);

            // 2. Update active file with new version full data
            await Context.UpdateAsync(activeFile, token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Gets the count of consecutive historical diff entries since the most recent full snapshot.
    /// </summary>
    public async Task<int> GetConsecutiveDiffCountAsync(int requestFileId, CancellationToken cancellationToken = default)
    {
        var recentHistory = await Context.SoapRequestFileHistories
            .Where(h => h.RequestFileId == requestFileId)
            .OrderByDescending(h => h.CreatedAt)
            .Select(h => h.FileData != null) // True if Full Snapshot, False if Diff
            .ToListAsync(cancellationToken);

        int diffCount = 0;
        foreach (var isFullSnapshot in recentHistory)
        {
            if (isFullSnapshot)
            {
                break; // Stop counting when we hit the last full snapshot
            }
            diffCount++;
        }

        return diffCount;
    }

    /// <summary>
    /// Updates the active file with full payload, and appends history as either a Diff or Full Snapshot depending on the 5-diff threshold.
    /// </summary>
    public async Task UpdateWithHistoryChainAsync(
        SoapRequestFile activeFile,
        string priorVersion,
        byte[]? compressedBackwardDiff,
        byte[]? compressedFullData,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Insert historical record for the replaced version
            var historyRecord = new SoapRequestFileHistory
            {
                RequestFileId = activeFile.Id,
                Version = priorVersion,
                FileData = compressedFullData, // Populated on 5th diff threshold reset
                DiffData = compressedBackwardDiff, // Populated when diff count < 5
                UncompressedSizeBytes = activeFile.UncompressedSizeBytes,
                FileHash = activeFile.FileHash,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = activeFile.LastUpdatedBy ?? activeFile.CreatedBy
            };

            await Context.InsertAsync(historyRecord, token: cancellationToken);

            // 2. Update active file record with the new full payload
            await Context.UpdateAsync(activeFile, token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Fetches an active request file by its parent operation ID and file name.
    /// </summary>
    /// <param name="operationId">The target operation identifier.</param>
    /// <param name="fileName">The request file name.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The matching <see cref="SoapRequestFile"/> or null if not found.</returns>
    public async Task<SoapRequestFile?> GetByOperationAndNameAsync(
        int operationId,
        string fileName,
        CancellationToken cancellationToken = default)
    {
        return await Context.SoapRequestFiles
            .FirstOrDefaultAsync(
                f => f.OperationId == operationId
                && f.FileName == fileName
                && f.IsActive,
                cancellationToken);
    }

    public async Task<PagedResult<SoapRequestFile>> GetPagedAsync(
        RequestFileFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapRequestFiles.AsQueryable();

        if (filter.OperationId.HasValue)
            query = query.Where(f => f.OperationId == filter.OperationId.Value);
        if (!string.IsNullOrWhiteSpace(filter.FileName))
            query = query.Where(f => f.FileName.Contains(filter.FileName));
        if (filter.IsActive.HasValue)
            query = query.Where(f => f.IsActive == filter.IsActive.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplySorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapRequestFile>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<SoapRequestFile> ApplySorting(IQueryable<SoapRequestFile> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(f => f.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "filename" => descending ? query.OrderByDescending(f => f.FileName) : query.OrderBy(f => f.FileName),
            "createdat" => descending ? query.OrderByDescending(f => f.CreatedAt) : query.OrderBy(f => f.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(f => f.CreatedBy) : query.OrderBy(f => f.CreatedBy),
            "version" => descending ? query.OrderByDescending(f => f.Version) : query.OrderBy(f => f.Version),
            "isactive" => descending ? query.OrderByDescending(f => f.IsActive) : query.OrderBy(f => f.IsActive),
            _ => query.OrderBy(f => f.Id)
        };
    }
}