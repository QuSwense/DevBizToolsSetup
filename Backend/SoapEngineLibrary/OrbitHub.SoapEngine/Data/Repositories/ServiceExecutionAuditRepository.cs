namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using LinqToDB.Data;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides data access for SOAP execution auditing using the unified ServiceAppDbContext.
/// Uses DirectExecutionAudit for run tracking and DirectExecutionAuditResponseFileLink
/// for per-file execution results.
/// </summary>
public class ServiceExecutionAuditRepository(ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    #region Execution Audit (Run) Operations

    /// <summary>
    /// Creates a new execution audit record (equivalent to starting a run).
    /// </summary>
    public async Task<DirectExecutionAudit> CreateAuditAsync(
        string name,
        string executedBy,
        CancellationToken cancellationToken = default)
    {
        var audit = new DirectExecutionAudit
        {
            Name = name,
            ExecutedAt = DateTime.UtcNow,
            ExecutionStatus = "InProgress",
            ExecutedBy = executedBy
        };

        var auditId = await Context.InsertWithInt32IdentityAsync(audit, token: cancellationToken);
        audit.Id = auditId;
        return audit;
    }

    /// <summary>
    /// Updates the status and completion timestamp of an execution audit.
    /// </summary>
    public async Task CompleteAuditAsync(
        int auditId,
        string status,
        string? executionDetails = null,
        CancellationToken cancellationToken = default)
    {
        await Context.DirectExecutionAudits
            .Where(a => a.Id == auditId)
            .Set(a => a.ExecutionStatus, status)
            .Set(a => a.ExecutionCompletedAt, DateTime.UtcNow)
            .Set(a => a.ExecutionDetails, executionDetails)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Fetches an execution audit by its primary key ID.
    /// </summary>
    public async Task<DirectExecutionAudit?> GetAuditByIdAsync(int auditId, CancellationToken cancellationToken = default)
    {
        return await Context.DirectExecutionAudits
            .FirstOrDefaultAsync(a => a.Id == auditId, cancellationToken);
    }

    #endregion

    #region Execution Response Link Operations

    /// <summary>
    /// Creates a response file link record for a single request file execution.
    /// </summary>
    public async Task<DirectExecutionAuditResponseFileLink> AddResponseLinkAsync(
        DirectExecutionAuditResponseFileLink link,
        CancellationToken cancellationToken = default)
    {
        var linkId = await Context.InsertWithInt32IdentityAsync(link, token: cancellationToken);
        link.Id = linkId;
        return link;
    }

    /// <summary>
    /// Updates execution status, HTTP response status code, and latency timing for a response link.
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
        await Context.DirectExecutionAuditResponseFileLinks
            .Where(l => l.Id == linkId)
            .Set(l => l.ExecutionStatus, status)
            .Set(l => l.HttpStatusCode, httpStatusCode)
            .Set(l => l.HttpRequestDurationMs, httpRequestDurationMs)
            .Set(l => l.HttpContentType, httpContentType)
            .Set(l => l.HttpRequestHeaders, httpRequestHeaders)
            .Set(l => l.HttpResponseHeaders, httpResponseHeaders)
            .Set(l => l.ExecutionCompletedAt, DateTime.UtcNow)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Gets all response links for a given audit, ordered by execution time.
    /// </summary>
    public async Task<List<DirectExecutionAuditResponseFileLink>> GetLinksByAuditIdAsync(int auditId, CancellationToken cancellationToken = default)
    {
        return await Context.DirectExecutionAuditResponseFileLinks
            .Where(l => l.DirectExecutionAuditId == auditId)
            .OrderBy(l => l.ExecutedAt)
            .ToListAsync(cancellationToken);
    }

    #endregion

    #region Response File Storage

    /// <summary>
    /// Saves the received HTTP response file payload atomically.
    /// </summary>
    public async Task<ServiceResponseFile> SaveResponseFileAsync(
        ServiceResponseFile responseFile,
        CancellationToken cancellationToken = default)
    {
        responseFile.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
        responseFile.IsBaseSnapshot = true;
        responseFile.DeltaDepth = 0;
        responseFile.CreatedAt = DateTime.UtcNow;
        responseFile.IsActive = true;

        var responseFileId = await Context.InsertWithInt32IdentityAsync(responseFile, token: cancellationToken);
        responseFile.Id = responseFileId;
        return responseFile;
    }

    #endregion

    #region Paged Queries

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
            query = query.Where(r => r.ServiceRequestFileId == serviceRequestFileId.Value);

        var total = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(r => r.CreatedAt)
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

    #region Sorting Helpers

    private static IQueryable<DirectExecutionAudit> ApplyAuditSorting(IQueryable<DirectExecutionAudit> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(a => a.ExecutedAt);

        return (sortBy.ToLowerInvariant()) switch
        {
            "name" => descending ? query.OrderByDescending(a => a.Name) : query.OrderBy(a => a.Name),
            "executedat" => descending ? query.OrderByDescending(a => a.ExecutedAt) : query.OrderBy(a => a.ExecutedAt),
            "executionstatus" or "status" => descending ? query.OrderByDescending(a => a.ExecutionStatus) : query.OrderBy(a => a.ExecutionStatus),
            "executedby" => descending ? query.OrderByDescending(a => a.ExecutedBy) : query.OrderBy(a => a.ExecutedBy),
            _ => query.OrderBy(a => a.ExecutedAt)
        };
    }

    private static IQueryable<DirectExecutionAuditResponseFileLink> ApplyLinkSorting(IQueryable<DirectExecutionAuditResponseFileLink> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(l => l.ExecutedAt);

        return (sortBy.ToLowerInvariant()) switch
        {
            "executedat" => descending ? query.OrderByDescending(l => l.ExecutedAt) : query.OrderBy(l => l.ExecutedAt),
            "executionstatus" or "status" => descending ? query.OrderByDescending(l => l.ExecutionStatus) : query.OrderBy(l => l.ExecutionStatus),
            "httpstatuscode" => descending ? query.OrderByDescending(l => l.HttpStatusCode) : query.OrderBy(l => l.HttpStatusCode),
            _ => query.OrderBy(l => l.ExecutedAt)
        };
    }

    #endregion

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
}