namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class SoapOperationRepository(SoapEngineDataContext context)
{
    private SoapEngineDataContext Context { get; } = context;

    /// <summary>
    /// Retrieves a <see cref="SoapOperation"/> by its primary key identifier.
    /// </summary>
    public async Task<SoapOperation?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.SoapOperations
            .FirstOrDefaultAsync(op => op.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves all operations registered under a specific application ID.
    /// </summary>
    public async Task<List<SoapOperation>> GetByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapOperations
            .Where(op => op.AppId == appId && op.IsActive)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Adds a manually configured SOAP operation along with optional target namespace and XSD schema entries.
    /// </summary>
    public async Task<SoapOperation> AddAsync(
        SoapOperation operation,
        string? targetNamespace = null,
        string? rawXsdSchema = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            var opId = await Context.InsertWithInt32IdentityAsync(operation, token: cancellationToken);
            operation.Id = opId;

            // Insert namespace definition tied to operation if provided
            if (!string.IsNullOrWhiteSpace(targetNamespace))
            {
                var ns = new SoapNamespace
                {
                    WsdlSyncId = operation.WsdlSyncId,
                    OperationId = opId,
                    Prefix = "tns",
                    NamespaceUri = targetNamespace,
                    CreatedAt = DateTime.UtcNow
                };
                await Context.InsertAsync(ns, token: cancellationToken);
            }

            // Insert optional XSD schema
            if (!string.IsNullOrWhiteSpace(rawXsdSchema))
            {
                var schema = new SoapOperationSchema
                {
                    WsdlSyncId = operation.WsdlSyncId,
                    OperationId = opId,
                    TargetNamespace = targetNamespace,
                    XsdContent = rawXsdSchema,
                    CreatedAt = DateTime.UtcNow
                };
                await Context.InsertAsync(schema, token: cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);
            return operation;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Adds multiple operations in bulk within a single execution transaction.
    /// </summary>
    public async Task AddRangeAsync(IEnumerable<SoapOperation> operations, CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            foreach (var op in operations)
            {
                var id = await Context.InsertWithInt32IdentityAsync(op, token: cancellationToken);
                op.Id = id;
            }

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Updates an existing operation's metadata.
    /// </summary>
    public async Task UpdateAsync(SoapOperation operation, CancellationToken cancellationToken = default)
    {
        await Context.UpdateAsync(operation, token: cancellationToken);
    }

    public async Task<PagedResult<SoapOperation>> GetPagedAsync(
        OperationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapOperations.AsQueryable();

        if (filter.AppId.HasValue)
            query = query.Where(o => o.AppId == filter.AppId.Value);
        if (!string.IsNullOrWhiteSpace(filter.OperationName))
            query = query.Where(o => o.OperationName.Contains(filter.OperationName));
        if (filter.IsActive.HasValue)
            query = query.Where(o => o.IsActive == filter.IsActive.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplySorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapOperation>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<SoapOperation> ApplySorting(IQueryable<SoapOperation> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(o => o.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "operationname" => descending ? query.OrderByDescending(o => o.OperationName) : query.OrderBy(o => o.OperationName),
            "createdat" => descending ? query.OrderByDescending(o => o.CreatedAt) : query.OrderBy(o => o.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(o => o.CreatedBy) : query.OrderBy(o => o.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(o => o.IsActive) : query.OrderBy(o => o.IsActive),
            "soapaction" => descending ? query.OrderByDescending(o => o.SoapAction) : query.OrderBy(o => o.SoapAction),
            _ => query.OrderBy(o => o.Id)
        };
    }
}