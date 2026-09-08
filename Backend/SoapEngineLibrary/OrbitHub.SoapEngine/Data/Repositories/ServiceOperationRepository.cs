namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using LinqToDB.Data;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Repository for managing SOAP service operations using the unified ServiceAppDbContext.
/// Maps to ServiceOperations table with ServiceApplicationId FK.
/// </summary>
public class ServiceOperationRepository(ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Retrieves a ServiceOperation by its primary key identifier.
    /// </summary>
    public async Task<ServiceOperation?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceOperations
            .FirstOrDefaultAsync(op => op.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves all operations registered under a specific application ID.
    /// </summary>
    public async Task<List<ServiceOperation>> GetByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceOperations
            .Where(op => op.ServiceApplicationId == appId && op.IsActive)
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Adds a manually configured SOAP operation along with optional schema entries.
    /// </summary>
    public async Task<ServiceOperation> AddAsync(
        ServiceOperation operation,
        string? inputRootElementName = null,
        string? outputRootElementName = null,
        string? targetNamespace = null,
        string? rawXsdSchema = null,
        int? definitionSyncId = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            operation.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
            operation.CreatedAt = DateTime.UtcNow;

            var opId = await Context.InsertWithInt32IdentityAsync(operation, token: cancellationToken);
            operation.Id = opId;

            // Insert schema entry if any schema-related data is provided
            if (!string.IsNullOrWhiteSpace(inputRootElementName) ||
                !string.IsNullOrWhiteSpace(outputRootElementName) ||
                !string.IsNullOrWhiteSpace(rawXsdSchema))
            {
                var schema = new ServiceOperationSchema
                {
                    ServiceDefinitionSyncId = definitionSyncId ?? 0,
                    ServiceOperationId = opId,
                    InputRootElementName = inputRootElementName,
                    OutputRootElementName = outputRootElementName,
                    TargetNamespace = targetNamespace,
                    CompressedContent = !string.IsNullOrWhiteSpace(rawXsdSchema)
                        ? System.Text.Encoding.UTF8.GetBytes(rawXsdSchema)
                        : [],
                    CompressionAlgorithmType = "None",
                    RecordVersion = await GetNextVersionAsync(null, cancellationToken),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = operation.CreatedBy
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
    public async Task AddRangeAsync(IEnumerable<ServiceOperation> operations, CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            foreach (var op in operations)
            {
                op.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
                op.CreatedAt = DateTime.UtcNow;
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
    /// Updates an existing operation's metadata and refreshes RecordVersion.
    /// </summary>
    public async Task UpdateAsync(ServiceOperation operation, CancellationToken cancellationToken = default)
    {
        operation.RecordVersion = await GetNextVersionAsync(operation.RecordVersion, cancellationToken);
        operation.LastUpdatedAt = DateTime.UtcNow;
        await Context.UpdateAsync(operation, token: cancellationToken);
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

    public async Task<PagedResult<ServiceOperation>> GetPagedAsync(
        OperationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.ServiceOperations.AsQueryable();

        if (filter.AppId.HasValue)
            query = query.Where(o => o.ServiceApplicationId == filter.AppId.Value);
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

        return new PagedResult<ServiceOperation>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<ServiceOperation> ApplySorting(IQueryable<ServiceOperation> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(o => o.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "operationname" => descending ? query.OrderByDescending(o => o.OperationName) : query.OrderBy(o => o.OperationName),
            "createdat" => descending ? query.OrderByDescending(o => o.CreatedAt) : query.OrderBy(o => o.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(o => o.CreatedBy) : query.OrderBy(o => o.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(o => o.IsActive) : query.OrderBy(o => o.IsActive),
            "endpointoraction" or "soapaction" => descending ? query.OrderByDescending(o => o.EndpointOrAction) : query.OrderBy(o => o.EndpointOrAction),
            _ => query.OrderBy(o => o.Id)
        };
    }
}