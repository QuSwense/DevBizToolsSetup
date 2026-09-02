namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Provides data access operations for managing SOAP request execution groups, execution batch runs,
/// individual item run states, and response persistence using LINQ to DB.
/// </summary>
public class SoapExecutionRepository(SoapEngineDataContext context)
{
    private SoapEngineDataContext Context { get; } = context;

    /// <summary>
    /// Maps a request file item to an execution group.
    /// </summary>
    public async Task<SoapExecutionGroupItem> AddGroupItemAsync(SoapExecutionGroupItem item, CancellationToken cancellationToken = default)
    {
        var generatedId = await Context.InsertWithInt32IdentityAsync(item, token: cancellationToken);
        item.Id = generatedId;
        return item;
    }

    #region Execution Group Operations

    /// <summary>
    /// Creates an execution group along with its initial child request file execution items.
    /// </summary>
    public async Task<SoapExecutionGroup> CreateGroupAsync(
        SoapExecutionGroup group,
        IEnumerable<SoapExecutionGroupItem> items,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            var groupId = await Context.InsertWithInt32IdentityAsync(group, token: cancellationToken);
            group.Id = groupId;

            foreach (var item in items)
            {
                item.ExecutionGroupId = groupId;
                await Context.InsertAsync(item, token: cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);
            return group;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Fetches an execution group by its primary key ID.
    /// </summary>
    public async Task<SoapExecutionGroup?> GetGroupByIdAsync(int groupId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapExecutionGroups
            .FirstOrDefaultAsync(g => g.Id == groupId, cancellationToken);
    }

    /// <summary>
    /// Gets all execution items registered under an execution group, ordered by ExecutionOrder.
    /// </summary>
    public async Task<List<SoapExecutionGroupItem>> GetGroupItemsAsync(int groupId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapExecutionGroupItems
            .Where(i => i.ExecutionGroupId == groupId)
            .OrderBy(i => i.ExecutionOrder)
            .ToListAsync(cancellationToken);
    }

    #endregion

    #region Execution Run Tracking

    /// <summary>
    /// Starts a new batch execution run for a group, initializing status as 'Pending' or 'InProgress'.
    /// </summary>
    public async Task<SoapExecutionRun> StartExecutionRunAsync(
        int executionGroupId,
        string executedBy,
        CancellationToken cancellationToken = default)
    {
        var run = new SoapExecutionRun
        {
            ExecutionGroupId = executionGroupId,
            RunStatus = EExecutionStatus.InProgress.ToDbString(),
            ExecutedBy = executedBy,
            StartedAt = DateTime.UtcNow
        };

        var runId = await Context.InsertWithInt32IdentityAsync(run, token: cancellationToken);
        run.Id = runId;
        return run;
    }

    /// <summary>
    /// Updates the status and completion timestamp of an execution run batch.
    /// </summary>
    public async Task CompleteExecutionRunAsync(
        int runId,
        EExecutionStatus status,
        CancellationToken cancellationToken = default)
    {
        await Context.SoapExecutionRuns
            .Where(r => r.Id == runId)
            .Set(r => r.RunStatus, status.ToDbString())
            .Set(r => r.CompletedAt, DateTime.UtcNow)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Adds an item execution entry for a specific request file within an execution run batch.
    /// </summary>
    public async Task<SoapExecutionItemRun> AddItemRunAsync(
        SoapExecutionItemRun itemRun,
        CancellationToken cancellationToken = default)
    {
        var itemRunId = await Context.InsertWithInt32IdentityAsync(itemRun, token: cancellationToken);
        itemRun.Id = itemRunId;
        return itemRun;
    }

    /// <summary>
    /// Updates execution status, HTTP response status code, and latency timing for an item run.
    /// </summary>
    public async Task UpdateItemRunStatusAsync(
        int itemRunId,
        EItemExecutionStatus status,
        int? httpStatusCode,
        int? executionTimeMs,
        CancellationToken cancellationToken = default)
    {
        await Context.SoapExecutionItemRuns
            .Where(ir => ir.Id == itemRunId)
            .Set(ir => ir.ItemExecutionStatus, status.ToDbString())
            .Set(ir => ir.HttpStatusCode, httpStatusCode)
            .Set(ir => ir.ExecutionTimeMs, executionTimeMs)
            .UpdateAsync(token: cancellationToken);
    }

    #endregion

    #region Response & Attachment Storage

    /// <summary>
    /// Saves the received HTTP response file payload and optional binary embeddings/attachments atomically.
    /// </summary>
    public async Task<SoapResponseFile> SaveResponseFileAsync(
        SoapResponseFile responseFile,
        IEnumerable<SoapResponseEmbedding>? embeddings = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            var responseFileId = await Context.InsertWithInt32IdentityAsync(responseFile, token: cancellationToken);
            responseFile.Id = responseFileId;

            if (embeddings is not null)
            {
                foreach (var attachment in embeddings)
                {
                    attachment.ResponseFileId = responseFileId;
                    await Context.InsertAsync(attachment, token: cancellationToken);
                }
            }

            await transaction.CommitAsync(cancellationToken);
            return responseFile;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    #endregion

    public async Task<PagedResult<SoapExecutionGroup>> GetGroupsPagedAsync(
        ExecutionGroupFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapExecutionGroups.AsQueryable();

        if (filter.AppId.HasValue)
            query = query.Where(g => g.AppId == filter.AppId.Value);
        if (!string.IsNullOrWhiteSpace(filter.GroupName))
            query = query.Where(g => g.GroupName.Contains(filter.GroupName));
        if (filter.IsActive.HasValue)
            query = query.Where(g => g.IsActive == filter.IsActive.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplyGroupSorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapExecutionGroup>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<SoapExecutionGroup> ApplyGroupSorting(IQueryable<SoapExecutionGroup> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(g => g.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "groupname" => descending ? query.OrderByDescending(g => g.GroupName) : query.OrderBy(g => g.GroupName),
            "createdat" => descending ? query.OrderByDescending(g => g.CreatedAt) : query.OrderBy(g => g.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(g => g.CreatedBy) : query.OrderBy(g => g.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(g => g.IsActive) : query.OrderBy(g => g.IsActive),
            _ => query.OrderBy(g => g.Id)
        };
    }

    public async Task<PagedResult<SoapExecutionRun>> GetRunsPagedAsync(
        ExecutionRunFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapExecutionRuns.AsQueryable();

        if (filter.ExecutionGroupId.HasValue)
            query = query.Where(r => r.ExecutionGroupId == filter.ExecutionGroupId.Value);
        if (!string.IsNullOrWhiteSpace(filter.RunStatus))
            query = query.Where(r => r.RunStatus == filter.RunStatus);
        if (!string.IsNullOrWhiteSpace(filter.ExecutedBy))
            query = query.Where(r => r.ExecutedBy == filter.ExecutedBy);
        if (filter.StartedFrom.HasValue)
            query = query.Where(r => r.StartedAt >= filter.StartedFrom.Value);
        if (filter.StartedTo.HasValue)
            query = query.Where(r => r.StartedAt <= filter.StartedTo.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplyRunSorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapExecutionRun>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<SoapExecutionRun> ApplyRunSorting(IQueryable<SoapExecutionRun> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(r => r.StartedAt);

        return (sortBy.ToLowerInvariant()) switch
        {
            "startedat" => descending ? query.OrderByDescending(r => r.StartedAt) : query.OrderBy(r => r.StartedAt),
            "completedat" => descending ? query.OrderByDescending(r => r.CompletedAt) : query.OrderBy(r => r.CompletedAt),
            "runstatus" => descending ? query.OrderByDescending(r => r.RunStatus) : query.OrderBy(r => r.RunStatus),
            "executedby" => descending ? query.OrderByDescending(r => r.ExecutedBy) : query.OrderBy(r => r.ExecutedBy),
            _ => query.OrderBy(r => r.StartedAt)
        };
    }

    public async Task<PagedResult<SoapResponseFile>> GetResponseFilesPagedAsync(
        int? executionItemRunId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapResponseFiles.AsQueryable();

        if (executionItemRunId.HasValue)
            query = query.Where(r => r.ExecutionItemRunId == executionItemRunId.Value);

        var total = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(r => r.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapResponseFile>
        {
            Items = items,
            TotalCount = total,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }
}