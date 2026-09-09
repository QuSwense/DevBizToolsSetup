namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.Repositories.TestManagement.Repositories;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Repository for managing SOAP service operations using stored procedure repositories
/// from OrbitHub.Data. Wraps SP calls and maps results to entity types.
/// Paged/read queries use direct linq2db (hybrid approach).
/// </summary>
public class ServiceOperationRepository(
    CreateServiceOperationRepository createOpRepo,
    CreateServiceOperationWithSchemaRepository createOpWithSchemaRepo,
    UpdateServiceOperationRepository updateOpRepo,
    GetServiceOperationByIdRepository getByIdRepo,
    GetServiceOperationsRepository getOpsRepo,
    ActivateServiceOperationRepository activateOpRepo,
    IUnitOfWork unitOfWork,
    ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Retrieves a ServiceOperation by its primary key identifier via SP.
    /// </summary>
    public async Task<ServiceOperation?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await getByIdRepo.ExecuteAsync(
            new GetServiceOperationByIdInput { Id = id }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        return MapToEntity(result.Data);
    }

    /// <summary>
    /// Retrieves all operations registered under a specific application ID via SP.
    /// </summary>
    public async Task<List<ServiceOperation>> GetByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        // First resolve the app's PublicId
        var app = await Context.ServiceApplications
            .Where(a => a.Id == appId)
            .Select(a => new { a.PublicId })
            .FirstOrDefaultAsync(cancellationToken);

        if (app is null)
            return [];

        var result = await getOpsRepo.ExecuteAsync(new GetServiceOperationsInput
        {
            ServiceApplicationPublicId = app.PublicId,
            IncludeInactive = false,
            OperationName = null
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            return [];

        return result.Data.Select(MapFromOpsOutput).ToList();
    }

    /// <summary>
    /// Adds a manually configured SOAP operation along with optional schema entries via composite SP.
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
        var result = await createOpWithSchemaRepo.ExecuteAsync(new CreateServiceOperationWithSchemaInput
        {
            ServiceApplicationId = operation.ServiceApplicationId,
            OperationName = operation.OperationName,
            EndpointOrAction = operation.EndpointOrAction,
            HttpMethod = null,
            Description = operation.Description,
            InputRootElementName = inputRootElementName,
            OutputRootElementName = outputRootElementName,
            TargetNamespace = targetNamespace,
            CompressedSchemaContent = !string.IsNullOrWhiteSpace(rawXsdSchema)
                ? System.Text.Encoding.UTF8.GetBytes(rawXsdSchema)
                : null,
            UserId = operation.CreatedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to create operation: {result.ErrorMessage}");

        return MapToEntity(result.Data);
    }

    /// <summary>
    /// Adds multiple operations in bulk within a single execution transaction.
    /// </summary>
    public async Task AddRangeAsync(IEnumerable<ServiceOperation> operations, CancellationToken cancellationToken = default)
    {
        await unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            foreach (var op in operations)
            {
                var result = await createOpRepo.ExecuteAsync(new CreateServiceOperationInput
                {
                    ServiceApplicationPublicId = Guid.Empty, // Will be resolved by SP
                    OperationName = op.OperationName,
                    EndpointOrAction = op.EndpointOrAction,
                    HttpMethod = null,
                    Description = op.Description,
                    UserId = op.CreatedBy
                }, cancellationToken);

                if (!result.Success)
                    throw new InvalidOperationException($"Failed to create operation '{op.OperationName}': {result.ErrorMessage}");
            }

            await unitOfWork.CommitAsync(cancellationToken);
        }
        catch
        {
            await unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Updates an existing operation's metadata via UpdateServiceOperation SP.
    /// </summary>
    public async Task UpdateAsync(ServiceOperation operation, CancellationToken cancellationToken = default)
    {
        var result = await updateOpRepo.ExecuteAsync(new UpdateServiceOperationInput
        {
            OperationId = operation.Id,
            OperationName = operation.OperationName,
            EndpointOrAction = operation.EndpointOrAction,
            HttpMethod = operation.HttpMethod,
            Description = operation.Description,
            IsActive = operation.IsActive,
            UserId = operation.LastUpdatedBy ?? operation.CreatedBy,
            RecordVersion = operation.RecordVersion
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update operation: {result.ErrorMessage}");
    }

    /// <summary>
    /// Paged query using direct linq2db (hybrid approach).
    /// </summary>
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

    private static ServiceOperation MapToEntity(GetServiceOperationByIdOutput dto)
    {
        return new ServiceOperation
        {
            Id = dto.Id,
            ServiceApplicationId = dto.ServiceApplicationId,
            OperationName = dto.OperationName,
            EndpointOrAction = dto.EndpointOrAction,
            HttpMethod = dto.HttpMethod,
            Description = dto.Description,
            IsActive = dto.IsActive,
            RecordVersion = dto.RecordVersion.ToString(),
            CreatedAt = dto.CreatedAt,
            CreatedBy = dto.CreatedBy,
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }

    private static ServiceOperation MapFromOpsOutput(GetServiceOperationsOutput dto)
    {
        return new ServiceOperation
        {
            Id = dto.OperationId ?? 0,
            ServiceApplicationId = dto.ServiceApplicationId ?? 0,
            OperationName = dto.OperationName ?? string.Empty,
            EndpointOrAction = dto.EndpointOrAction,
            HttpMethod = dto.HttpMethod,
            Description = dto.Description,
            IsActive = dto.IsActive ?? true,
            RecordVersion = dto.RecordVersion ?? "00.00.00",
            CreatedAt = dto.CreatedAt ?? DateTime.UtcNow,
            CreatedBy = dto.CreatedBy ?? "SYSTEM",
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }
}