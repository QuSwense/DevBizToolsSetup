namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using LinqToDB.Data;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Repository for managing SOAP service applications using the unified ServiceAppDbContext.
/// All queries filter by ServiceType = "SOAP".
/// Version generation is delegated to the database function dbo.fn_CalculateVersion.
/// </summary>
public class ServiceApplicationRepository(ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Retrieves the active authentication configuration for a specific application ID.
    /// Uses the ServiceAppAuthenticationId FK on ServiceApplication.
    /// </summary>
    public async Task<ServiceAppAuthentication?> GetAuthenticationByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        var app = await Context.ServiceApplications
            .FirstOrDefaultAsync(a => a.Id == appId, cancellationToken);

        if (app?.ServiceAppAuthenticationId is null)
            return null;

        return await Context.ServiceAppAuthentications
            .FirstOrDefaultAsync(a => a.Id == app.ServiceAppAuthenticationId.Value && a.IsActive, cancellationToken);
    }

    /// <summary>
    /// Inserts a new SOAP application record with ServiceType = "SOAP", a generated PublicId,
    /// and a RecordVersion computed by the database function.
    /// </summary>
    public async Task<ServiceApplication> AddAsync(ServiceApplication app, CancellationToken cancellationToken = default)
    {
        app.ServiceType = "SOAP";
        app.PublicId = Guid.NewGuid();
        app.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
        app.CreatedAt = DateTime.UtcNow;

        var generatedId = await Context.InsertWithInt32IdentityAsync(app, token: cancellationToken);
        app.Id = generatedId;
        return app;
    }

    /// <summary>
    /// Retrieves a ServiceApplication by its primary key identifier.
    /// </summary>
    public async Task<ServiceApplication?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceApplications
            .FirstOrDefaultAsync(app => app.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves a ServiceApplication by its unique name.
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
    /// Updates an existing ServiceApplication record and refreshes its RecordVersion.
    /// </summary>
    public async Task UpdateAsync(ServiceApplication app, CancellationToken cancellationToken = default)
    {
        app.RecordVersion = await GetNextVersionAsync(app.RecordVersion, cancellationToken);
        app.LastUpdatedAt = DateTime.UtcNow;
        await Context.UpdateAsync(app, token: cancellationToken);
    }

    /// <summary>
    /// Updates active state status and audit tracking columns for a targeted application ID.
    /// </summary>
    public async Task UpdateStatusAsync(int appId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        var nextVersion = await GetNextVersionAsync(null, cancellationToken);
        await Context.ServiceApplications
            .Where(app => app.Id == appId)
            .Set(app => app.IsActive, isActive)
            .Set(app => app.RecordVersion, nextVersion)
            .Set(app => app.LastUpdatedAt, DateTime.UtcNow)
            .Set(app => app.LastUpdatedBy, updatedBy)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Inserts or updates authentication configuration for a SOAP application.
    /// Sets the ServiceAppAuthenticationId FK on the ServiceApplication record.
    /// </summary>
    public async Task SaveAuthenticationAsync(ServiceAppAuthentication auth, int appId, CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // Deactivate any existing active auth records for this app
            await Context.ServiceAppAuthentications
                .Where(a => a.ServiceApplications.Any(sa => sa.Id == appId) && a.IsActive)
                .Set(a => a.IsActive, false)
                .Set(a => a.LastUpdatedAt, DateTime.UtcNow)
                .UpdateAsync(token: cancellationToken);

            // Insert new auth record
            auth.PublicId = Guid.NewGuid();
            auth.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
            auth.CreatedAt = DateTime.UtcNow;
            auth.IsActive = true;

            var authId = await Context.InsertWithInt64IdentityAsync(auth, token: cancellationToken);
            auth.Id = authId;

            // Update the ServiceApplication FK
            await Context.ServiceApplications
                .Where(app => app.Id == appId)
                .Set(app => app.ServiceAppAuthenticationId, authId)
                .Set(app => app.LastUpdatedAt, DateTime.UtcNow)
                .UpdateAsync(token: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Calls the database function dbo.fn_CalculateVersion to compute the next version string.
    /// </summary>
    public async Task<string> GetNextVersionAsync(string? previousVersion, CancellationToken cancellationToken = default)
    {
        var param = previousVersion is not null
            ? new DataParameter("@PreviousVersion", previousVersion)
            : new DataParameter("@PreviousVersion", DBNull.Value);

        var result = await Context.QueryAsync<string>(
            "SELECT dbo.fn_CalculateVersion(@PreviousVersion)", param);

        return result.FirstOrDefault() ?? "00.00.00";
    }

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
            "appname" or "name" => descending ? query.OrderByDescending(a => a.Name) : query.OrderBy(a => a.Name),
            "createdat" => descending ? query.OrderByDescending(a => a.CreatedAt) : query.OrderBy(a => a.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(a => a.CreatedBy) : query.OrderBy(a => a.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(a => a.IsActive) : query.OrderBy(a => a.IsActive),
            "version" or "recordversion" => descending ? query.OrderByDescending(a => a.RecordVersion) : query.OrderBy(a => a.RecordVersion),
            _ => query.OrderBy(a => a.Id)
        };
    }
}