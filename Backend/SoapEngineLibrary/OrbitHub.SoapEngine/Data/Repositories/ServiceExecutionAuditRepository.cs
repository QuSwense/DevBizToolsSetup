namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.Repositories.TestManagement.Repositories;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides data access for SOAP execution auditing using stored procedure repositories
/// from OrbitHub.Data. Uses DirectExecutionAudit for run tracking and
/// DirectExecutionAuditResponseFileLink for per-file execution results.
/// Paged queries use direct linq2db (hybrid approach).
/// </summary>
public class ServiceExecutionAuditRepository(
    CreateDirectExecutionAuditRepository createAuditRepo,
    CompleteDirectExecutionAuditRepository completeAuditRepo,
    GetDirectExecutionAuditByIdRepository getAuditByIdRepo,
    CreateDirectExecutionAuditResponseFileLinkRepository createLinkRepo,
    UpdateDirectExecutionAuditResponseFileLinkStatusRepository updateLinkStatusRepo,
    GetDirectExecutionAuditResponseFileLinksByAuditIdRepository getLinksByAuditIdRepo,
    InsertServiceResponseFileRepository insertResponseFileRepo,
    InsertServiceResponseFileEmbeddingRepository insertResponseEmbeddingRepo,
    IUnitOfWork unitOfWork,
    ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    #region Execution Audit (Run) Operations

    /// <summary>
    /// Creates a new execution audit record via usp_CreateDirectExecutionAudit SP.
    /// </summary>
    public async Task<DirectExecutionAudit> CreateAuditAsync(
        string name,
        string executedBy,
        CancellationToken cancellationToken = default)
    {
        var result = await createAuditRepo.ExecuteAsync(new CreateDirectExecutionAuditInput
        {
            Name = name,
            ExecutedBy = executedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to create execution audit: {result.ErrorMessage}");

        var dto = result.Data;
        return new DirectExecutionAudit
        {
            Id = dto.AuditId,
            Name = dto.Name,
            ExecutionStatus = dto.ExecutionStatus,
            ExecutedAt = dto.ExecutedAt,
            ExecutedBy = dto.ExecutedBy
        };
    }

    /// <summary>
    /// Updates the status and completion timestamp of an execution audit via SP.
    /// </summary>
    public async Task CompleteAuditAsync(
        int auditId,
        string status,
        string? executionDetails = null,
        CancellationToken cancellationToken = default)
    {
        var result = await completeAuditRepo.ExecuteAsync(new CompleteDirectExecutionAuditInput
        {
            AuditId = auditId,
            ExecutionStatus = status,
            ExecutionDetails = executionDetails
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to complete execution audit: {result.ErrorMessage}");
    }

    /// <summary>
    /// Fetches an execution audit by its primary key ID via SP.
    /// </summary>
    public async Task<DirectExecutionAudit?> GetAuditByIdAsync(int auditId, CancellationToken cancellationToken = default)
    {
        var result = await getAuditByIdRepo.ExecuteAsync(
            new GetDirectExecutionAuditByIdInput { AuditId = auditId }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        var dto = result.Data;
        return new DirectExecutionAudit
        {
            Id = dto.Id,
            Name = dto.Name,
            ExecutedAt = dto.ExecutedAt,
            ExecutionStatus = dto.ExecutionStatus,
            ExecutionCompletedAt = dto.ExecutionCompletedAt,
            ExecutionDetails = dto.ExecutionDetails,
            ExecutedBy = dto.ExecutedBy
        };
    }

    #endregion

    #region Execution Response Link Operations

    /// <summary>
    /// Creates a response file link record for a single request file execution via SP.
    /// </summary>
    public async Task<DirectExecutionAuditResponseFileLink> AddResponseLinkAsync(
        DirectExecutionAuditResponseFileLink link,
        CancellationToken cancellationToken = default)
    {
        var result = await createLinkRepo.ExecuteAsync(new CreateDirectExecutionAuditResponseFileLinkInput
        {
            DirectExecutionAuditId = link.DirectExecutionAuditId,
            ServiceRequestFileId = link.ServiceRequestFileId,
            ExecutionOrder = 0,
            ExecutedBy = null
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to create response link: {result.ErrorMessage}");

        var dto = result.Data;
        return new DirectExecutionAuditResponseFileLink
        {
            Id = dto.Id,
            DirectExecutionAuditId = dto.DirectExecutionAuditId,
            ServiceRequestFileId = dto.ServiceRequestFileId,
            ExecutionStatus = dto.ExecutionStatus,
            ExecutedAt = dto.ExecutedAt
        };
    }

    /// <summary>
    /// Updates execution status, HTTP response status code, and latency timing for a response link via SP.
    /// </summary>
    public async Task UpdateResponseLinkStatusAsync(
        int linkId,
        string status,
        int? httpStatusCode,
        int? httpRequestDurationMs,
        string? httpContentType = null,
        string? httpRequestHeaders = null,
        string? httpResponseHeaders = null,
        CancellationToken cancellationToken = default)
    {
        var result = await updateLinkStatusRepo.ExecuteAsync(new UpdateDirectExecutionAuditResponseFileLinkStatusInput
        {
            LinkId = linkId,
            ExecutionStatus = status,
            HttpStatusCode = httpStatusCode,
            HttpRequestDurationMs = httpRequestDurationMs,
            HttpContentType = httpContentType,
            HttpRequestHeaders = httpRequestHeaders,
            HttpResponseHeaders = httpResponseHeaders
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update response link status: {result.ErrorMessage}");
    }

    /// <summary>
    /// Gets all response links for a given audit via SP.
    /// </summary>
    public async Task<List<DirectExecutionAuditResponseFileLink>> GetLinksByAuditIdAsync(int auditId, CancellationToken cancellationToken = default)
    {
        var result = await getLinksByAuditIdRepo.ExecuteAsync(
            new GetDirectExecutionAuditResponseFileLinksByAuditIdInput { DirectExecutionAuditId = auditId }, cancellationToken);

        if (!result.Success || result.Data is null)
            return [];

        return result.Data.Select(dto => new DirectExecutionAuditResponseFileLink
        {
            Id = dto.Id,
            DirectExecutionAuditId = dto.DirectExecutionAuditId,
            ServiceRequestFileId = dto.ServiceRequestFileId,
            ExecutionStatus = dto.ExecutionStatus,
            HttpStatusCode = dto.HttpStatusCode,
            HttpRequestDurationMs = dto.HttpRequestDurationMs,
            HttpContentType = dto.HttpContentType,
            HttpRequestHeaders = dto.HttpRequestHeaders,
            HttpResponseHeaders = dto.HttpResponseHeaders,
            ExecutedAt = dto.ExecutedAt,
            ExecutionCompletedAt = dto.ExecutionCompletedAt
        }).ToList();
    }

    #endregion

    #region Response File Storage

    /// <summary>
    /// Saves the received HTTP response file payload via usp_InsertServiceResponseFile SP.
    /// </summary>
    public async Task<ServiceResponseFile> SaveResponseFileAsync(
        ServiceResponseFile responseFile,
        CancellationToken cancellationToken = default)
    {
        var result = await insertResponseFileRepo.ExecuteAsync(new InsertServiceResponseFileInput
        {
            ServiceRequestFileId = responseFile.ServiceRequestFileId,
            Name = responseFile.Name,
            FileFormat = responseFile.FileFormat,
            IsBaseSnapshot = true,
            ParentBaseId = null,
            ParentDeltaId = null,
            CompressedData = responseFile.CompressedData,
            UncompressedSizeBytes = responseFile.UncompressedSizeBytes,
            CompressionAlgorithmType = responseFile.CompressionAlgorithmType,
            FileHash = responseFile.ContentHash,
            UserId = responseFile.CreatedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to save response file: {result.ErrorMessage}");

        var dto = result.Data;
        return new ServiceResponseFile
        {
            Id = dto.ResponseFileId!.Value,
            ServiceRequestFileId = dto.ServiceRequestFileId!.Value,
            Name = dto.Name!,
            FileFormat = dto.FileFormat,
            IsBaseSnapshot = dto.IsBaseSnapshot ?? true,
            ParentBaseId = dto.ParentBaseId,
            ParentDeltaId = dto.ParentDeltaId,
            DeltaDepth = dto.DeltaDepth ?? 0,
            CompressedData = dto.CompressedData ?? responseFile.CompressedData,
            UncompressedSizeBytes = dto.UncompressedSizeBytes,
            CompressionAlgorithmType = dto.CompressionAlgorithmType,
            ContentHash = dto.FileHash,
            RecordVersion = dto.RecordVersion ?? "00.00.00",
            IsActive = true,
            CreatedAt = dto.CreatedAt ?? DateTime.UtcNow,
            CreatedBy = dto.CreatedBy ?? responseFile.CreatedBy
        };
    }

    #endregion

    #region Paged Queries (Hybrid — direct linq2db)

    public async Task<PagedResult<DirectExecutionAudit>> GetAuditsPagedAsync(
        ExecutionAuditFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.DirectExecutionAudits.AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.Name))
            query = query.Where(a => a.Name.Contains(filter.Name));
        if (!string.IsNullOrWhiteSpace(filter.ExecutionStatus))
            query = query.Where(a => a.ExecutionStatus == filter.ExecutionStatus);
        if (!string.IsNullOrWhiteSpace(filter.ExecutedBy))
            query = query.Where(a => a.ExecutedBy == filter.ExecutedBy);
        if (filter.ExecutedFrom.HasValue)
            query = query.Where(a => a.ExecutedAt >= filter.ExecutedFrom.Value);
        if (filter.ExecutedTo.HasValue)
            query = query.Where(a => a.ExecutedAt <= filter.ExecutedTo.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplyAuditSorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<DirectExecutionAudit>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    public async Task<PagedResult<DirectExecutionAuditResponseFileLink>> GetResponseLinksPagedAsync(
        ExecutionAuditLinkFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.DirectExecutionAuditResponseFileLinks.AsQueryable();

        if (filter.DirectExecutionAuditId.HasValue)
            query = query.Where(l => l.DirectExecutionAuditId == filter.DirectExecutionAuditId.Value);
        if (!string.IsNullOrWhiteSpace(filter.ExecutionStatus))
            query = query.Where(l => l.ExecutionStatus == filter.ExecutionStatus);

        var total = await query.CountAsync(cancellationToken);

        query = ApplyLinkSorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<DirectExecutionAuditResponseFileLink>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    public async Task<PagedResult<ServiceResponseFile>> GetResponseFilesPagedAsync(
        int? serviceRequestFileId,
        int pageNumber = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var query = Context.ServiceResponseFiles.AsQueryable();

        if (serviceRequestFileId.HasValue)
            query = query.Where(f => f.ServiceRequestFileId == serviceRequestFileId.Value);

        var total = await query.CountAsync(cancellationToken);

        query = query.OrderByDescending(f => f.CreatedAt);

        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<ServiceResponseFile>
        {
            Items = items,
            TotalCount = total,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }

    #endregion

    private static IQueryable<DirectExecutionAudit> ApplyAuditSorting(IQueryable<DirectExecutionAudit> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderByDescending(a => a.ExecutedAt);

        return (sortBy.ToLowerInvariant()) switch
        {
            "name" => descending ? query.OrderByDescending(a => a.Name) : query.OrderBy(a => a.Name),
            "executedat" => descending ? query.OrderByDescending(a => a.ExecutedAt) : query.OrderBy(a => a.ExecutedAt),
            "executionstatus" => descending ? query.OrderByDescending(a => a.ExecutionStatus) : query.OrderBy(a => a.ExecutionStatus),
            "executedby" => descending ? query.OrderByDescending(a => a.ExecutedBy) : query.OrderBy(a => a.ExecutedBy),
            _ => query.OrderByDescending(a => a.ExecutedAt)
        };
    }

    private static IQueryable<DirectExecutionAuditResponseFileLink> ApplyLinkSorting(IQueryable<DirectExecutionAuditResponseFileLink> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(l => l.ExecutedAt);

        return (sortBy.ToLowerInvariant()) switch
        {
            "executedat" => descending ? query.OrderByDescending(l => l.ExecutedAt) : query.OrderBy(l => l.ExecutedAt),
            "executionstatus" => descending ? query.OrderByDescending(l => l.ExecutionStatus) : query.OrderBy(l => l.ExecutionStatus),
            _ => query.OrderBy(l => l.ExecutedAt)
        };
    }
}