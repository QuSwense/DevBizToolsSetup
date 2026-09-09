namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.Repositories.TestManagement.Repositories;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Repository for managing SOAP service applications using stored procedure repositories
/// from OrbitHub.Data. Wraps SP calls and maps results to entity types.
/// Paged/read queries use direct linq2db (hybrid approach).
/// </summary>
public class ServiceApplicationRepository(
    CreateServiceApplicationRepository createAppRepo,
    GetServiceApplicationByIdRepository getByIdRepo,
    UpsertServiceApplicationRepository upsertRepo,
    UpdateServiceAppAuthenticationRepository updateAuthRepo,
    GetServiceAppAuthenticationByAppIdRepository getAuthByAppIdRepo,
    ToggleServiceApplicationActiveRepository toggleActiveRepo,
    IUnitOfWork unitOfWork,
    ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Retrieves the active authentication configuration for a specific application ID.
    /// Uses the GetServiceAppAuthenticationByAppId SP.
    /// </summary>
    public async Task<ServiceAppAuthentication?> GetAuthenticationByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        var result = await getAuthByAppIdRepo.ExecuteAsync(
            new GetServiceAppAuthenticationByAppIdInput { ServiceApplicationId = appId }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        var dto = result.Data;
        return new ServiceAppAuthentication
        {
            Id = dto.Id,
            PublicId = dto.PublicId,
            Name = dto.Name,
            AuthenticationType = dto.AuthenticationType,
            EncryptionAlgorithmType = dto.EncryptionAlgorithmType,
            EncryptedJson = dto.EncryptedJson,
            IsActive = dto.IsActive,
            RecordVersion = dto.RecordVersion.ToString(),
            CreatedAt = dto.CreatedAt,
            CreatedBy = dto.CreatedBy,
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }

    /// <summary>
    /// Inserts a new SOAP application record via usp_CreateServiceApplication SP.
    /// </summary>
    public async Task<ServiceApplication> AddAsync(ServiceApplication app, CancellationToken cancellationToken = default)
    {
        var result = await createAppRepo.ExecuteAsync(new CreateServiceApplicationInput
        {
            ServiceType = "SOAP",
            ServiceAppAuthenticationId = null,
            Name = app.Name,
            BaseUrl = app.BaseUrl,
            DefinitionType = "WSDL",
            DefinitionRelativeUrl = app.DefinitionRelativeUrl,
            HealthcheckRelativeUrl = app.HealthcheckRelativeUrl,
            Description = app.Description,
            UserId = app.CreatedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to create application: {result.ErrorMessage}");

        var dto = result.Data;
        return new ServiceApplication
        {
            Id = dto.InternalId ?? throw new InvalidOperationException("SP did not return a ServiceApplicationId."),
            PublicId = dto.PublicId ?? Guid.Empty,
            ServiceType = dto.ServiceType ?? "SOAP",
            Name = dto.Name ?? string.Empty,
            BaseUrl = dto.BaseUrl ?? string.Empty,
            DefinitionType = dto.DefinitionType,
            DefinitionRelativeUrl = dto.DefinitionRelativeUrl,
            HealthcheckRelativeUrl = dto.HealthcheckRelativeUrl,
            Description = dto.Description,
            IsActive = dto.IsActive ?? true,
            RecordVersion = dto.RecordVersion ?? "00.00.00",
            CreatedAt = dto.CreatedAt ?? DateTime.UtcNow,
            CreatedBy = dto.CreatedBy ?? app.CreatedBy
        };
    }

    /// <summary>
    /// Retrieves a ServiceApplication by its primary key identifier via SP.
    /// </summary>
    public async Task<ServiceApplication?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var result = await getByIdRepo.ExecuteAsync(
            new GetServiceApplicationByIdInput { Id = id }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        return MapToEntity(result.Data);
    }

    /// <summary>
    /// Retrieves a ServiceApplication by its unique name via direct query.
    /// </summary>
    public async Task<ServiceApplication?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceApplications
            .FirstOrDefaultAsync(app => app.Name == name, cancellationToken);
    }

    /// <summary>
    /// Fetches the latest RecordVersion string assigned to a SOAP application.
    /// </summary>
    public async Task<string?> GetLatestVersionAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceApplications
            .Where(app => app.Id == appId)
            .Select(app => app.RecordVersion)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Updates an existing ServiceApplication record via UpsertServiceApplication SP.
    /// </summary>
    public async Task UpdateAsync(ServiceApplication app, CancellationToken cancellationToken = default)
    {
        var result = await upsertRepo.ExecuteAsync(new UpsertServiceApplicationInput
        {
            PublicId = app.PublicId,
            RecordVersion = app.RecordVersion,
            ServiceType = app.ServiceType,
            ServiceAppAuthenticationId = null, // Auth is managed separately via SaveAuthenticationAsync
            Name = app.Name,
            BaseUrl = app.BaseUrl,
            DefinitionType = app.DefinitionType,
            DefinitionRelativeUrl = app.DefinitionRelativeUrl,
            HealthcheckRelativeUrl = app.HealthcheckRelativeUrl,
            Description = app.Description,
            UserId = app.LastUpdatedBy ?? app.CreatedBy,
            IsActive = app.IsActive,
            ActivityNotes = $"Updated application: {app.Name}"
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update application: {result.ErrorMessage}");
    }

    /// <summary>
    /// Updates active state status via ToggleServiceApplicationActive SP.
    /// </summary>
    public async Task UpdateStatusAsync(int appId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        // First resolve the app's PublicId
        var appResult = await getByIdRepo.ExecuteAsync(
            new GetServiceApplicationByIdInput { Id = appId }, cancellationToken);

        if (!appResult.Success || appResult.Data is null)
            throw new InvalidOperationException($"Application with ID {appId} not found.");

        var appPublicId = appResult.Data.PublicId;

        var result = await toggleActiveRepo.ExecuteAsync(new ToggleServiceApplicationActiveInput
        {
            PublicId = appPublicId,
            IsActive = isActive,
            UserId = updatedBy
        }, cancellationToken);

        if (!result.Success)
            throw new InvalidOperationException($"Failed to update application status: {result.ErrorMessage}");
    }

    /// <summary>
    /// Inserts or updates authentication configuration via UpdateServiceAppAuthentication SP.
    /// </summary>
    public async Task SaveAuthenticationAsync(ServiceAppAuthentication auth, int appId, CancellationToken cancellationToken = default)
    {
        await unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // First, get the current app to resolve its PublicId
            var appResult = await getByIdRepo.ExecuteAsync(
                new GetServiceApplicationByIdInput { Id = appId }, cancellationToken);

            if (!appResult.Success || appResult.Data is null)
                throw new InvalidOperationException($"Application with ID {appId} not found.");

            var app = appResult.Data;

            // Update auth via SP
            var authResult = await updateAuthRepo.ExecuteAsync(new UpdateServiceAppAuthenticationInput
            {
                PublicId = app.PublicId,
                Name = auth.Name,
                AuthenticationType = auth.AuthenticationType,
                EncryptionAlgorithmType = auth.EncryptionAlgorithmType,
                EncryptedJson = auth.EncryptedJson,
                UserId = auth.CreatedBy,
                ActivityNotes = $"Configured authentication for application ID {appId}"
            }, cancellationToken);

            if (!authResult.Success)
                throw new InvalidOperationException($"Failed to save authentication: {authResult.ErrorMessage}");

            await unitOfWork.CommitAsync(cancellationToken);
        }
        catch
        {
            await unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Paged query using direct linq2db (hybrid approach).
    /// </summary>
    public async Task<PagedResult<ServiceApplication>> GetPagedAsync(
        ApplicationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.ServiceApplications
            .Where(a => a.ServiceType == "SOAP")
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.AppName))
            query = query.Where(a => a.Name.Contains(filter.AppName));
        if (filter.IsActive.HasValue)
            query = query.Where(a => a.IsActive == filter.IsActive.Value);
        if (!string.IsNullOrWhiteSpace(filter.CreatedBy))
            query = query.Where(a => a.CreatedBy == filter.CreatedBy);
        if (filter.CreatedFrom.HasValue)
            query = query.Where(a => a.CreatedAt >= filter.CreatedFrom.Value);
        if (filter.CreatedTo.HasValue)
            query = query.Where(a => a.CreatedAt <= filter.CreatedTo.Value);

        var total = await query.CountAsync(cancellationToken);

        query = ApplySorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<ServiceApplication>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<ServiceApplication> ApplySorting(IQueryable<ServiceApplication> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(a => a.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "name" => descending ? query.OrderByDescending(a => a.Name) : query.OrderBy(a => a.Name),
            "createdat" => descending ? query.OrderByDescending(a => a.CreatedAt) : query.OrderBy(a => a.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(a => a.CreatedBy) : query.OrderBy(a => a.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(a => a.IsActive) : query.OrderBy(a => a.IsActive),
            _ => query.OrderBy(a => a.Id)
        };
    }

    private static ServiceApplication MapToEntity(GetServiceApplicationByIdOutput dto)
    {
        return new ServiceApplication
        {
            Id = dto.Id,
            PublicId = dto.PublicId,
            ServiceType = dto.ServiceType,
            ServiceAppAuthenticationId = dto.ServiceAppAuthenticationId,
            Name = dto.Name,
            BaseUrl = dto.BaseUrl,
            DefinitionType = dto.DefinitionType,
            DefinitionRelativeUrl = dto.DefinitionRelativeUrl,
            HealthcheckRelativeUrl = dto.HealthcheckRelativeUrl,
            Description = dto.Description,
            IsActive = dto.IsActive,
            RecordVersion = dto.RecordVersion.ToString(),
            CreatedAt = dto.CreatedAt,
            CreatedBy = dto.CreatedBy,
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }
}