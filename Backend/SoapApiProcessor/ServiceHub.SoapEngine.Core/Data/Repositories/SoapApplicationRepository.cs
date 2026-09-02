namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class SoapApplicationRepository(SoapEngineDataContext context)
{
    private SoapEngineDataContext Context { get; } = context;

    /// <summary>
    /// Retrieves the active authentication configuration for a specific application ID.
    /// </summary>
    public async Task<SoapAppAuthentication?> GetAuthenticationByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapAppAuthentications
            .FirstOrDefaultAsync(a => a.AppId == appId && a.IsActive, cancellationToken);
    }

    /// <summary>
    /// Inserts a new <see cref="SoapApplication"/> record into the database and returns the entity populated with its generated identity primary key.
    /// </summary>
    public async Task<SoapApplication> AddAsync(SoapApplication app, CancellationToken cancellationToken = default)
    {
        var generatedId = await Context.InsertWithInt32IdentityAsync(app, token: cancellationToken);
        app.Id = generatedId;
        return app;
    }

    /// <summary>
    /// Retrieves a <see cref="SoapApplication"/> by its primary key identifier.
    /// </summary>
    public async Task<SoapApplication?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await Context.SoapApplications
            .FirstOrDefaultAsync(app => app.Id == id, cancellationToken);
    }

    /// <summary>
    /// Retrieves a <see cref="SoapApplication"/> by its unique application name.
    /// </summary>
    public async Task<SoapApplication?> GetByNameAsync(string appName, CancellationToken cancellationToken = default)
    {
        return await Context.SoapApplications
            .FirstOrDefaultAsync(app => app.AppName == appName, cancellationToken);
    }

    /// <summary>
    /// Fetches the latest version string assigned to a SOAP application.
    /// </summary>
    public async Task<string?> GetLatestVersionAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapApplications
            .Where(app => app.Id == appId)
            .Select(app => app.Version)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Updates an existing <see cref="SoapApplication"/> record in full.
    /// </summary>
    public async Task UpdateAsync(SoapApplication app, CancellationToken cancellationToken = default)
    {
        await Context.UpdateAsync(app, token: cancellationToken);
    }

    /// <summary>
    /// Updates active state status and audit tracking columns for a targeted application ID.
    /// </summary>
    public async Task UpdateStatusAsync(int appId, bool isActive, string updatedBy, CancellationToken cancellationToken = default)
    {
        await Context.SoapApplications
            .Where(app => app.Id == appId)
            .Set(app => app.IsActive, isActive)
            .Set(app => app.LastUpdatedAt, DateTime.UtcNow)
            .Set(app => app.LastUpdatedBy, updatedBy)
            .UpdateAsync(token: cancellationToken);
    }

    /// <summary>
    /// Inserts a new authentication entry or updates an existing configuration for a specific application ID in SoapAppAuthentication.
    /// </summary>
    public async Task SaveAuthenticationAsync(SoapAppAuthentication auth, CancellationToken cancellationToken = default)
    {
        var existingAuth = await Context.SoapAppAuthentications
            .FirstOrDefaultAsync(a => a.AppId == auth.AppId, cancellationToken);

        if (existingAuth is null)
        {
            await Context.InsertAsync(auth, token: cancellationToken);
        }
        else
        {
            await Context.SoapAppAuthentications
                .Where(a => a.Id == existingAuth.Id)
                .Set(a => a.AuthenticationType, auth.AuthenticationType)
                .Set(a => a.EncryptedCredentialsJson, auth.EncryptedCredentialsJson)
                .Set(a => a.IsActive, auth.IsActive)
                .Set(a => a.LastUpdatedAt, DateTime.UtcNow)
                .Set(a => a.LastUpdatedBy, auth.CreatedBy)
                .UpdateAsync(token: cancellationToken);
        }
    }

    public async Task<PagedResult<SoapApplication>> GetPagedAsync(
        ApplicationFilter filter,
        CancellationToken cancellationToken = default)
    {
        var query = Context.SoapApplications.AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.AppName))
            query = query.Where(a => a.AppName.Contains(filter.AppName));
        if (filter.IsActive.HasValue)
            query = query.Where(a => a.IsActive == filter.IsActive.Value);
        if (!string.IsNullOrWhiteSpace(filter.CreatedBy))
            query = query.Where(a => a.CreatedBy == filter.CreatedBy);
        if (filter.CreatedFrom.HasValue)
            query = query.Where(a => a.CreatedAt >= filter.CreatedFrom.Value);
        if (filter.CreatedTo.HasValue)
            query = query.Where(a => a.CreatedAt <= filter.CreatedTo.Value);

        var total = await query.CountAsync(cancellationToken);

        // Apply sorting (switch on known column names)
        query = ApplySorting(query, filter.SortBy, filter.SortDescending);

        var items = await query
            .Skip((filter.PageNumber - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<SoapApplication>
        {
            Items = items,
            TotalCount = total,
            PageNumber = filter.PageNumber,
            PageSize = filter.PageSize
        };
    }

    private static IQueryable<SoapApplication> ApplySorting(IQueryable<SoapApplication> query, string? sortBy, bool descending)
    {
        if (string.IsNullOrWhiteSpace(sortBy))
            return query.OrderBy(a => a.Id);

        return (sortBy.ToLowerInvariant()) switch
        {
            "appname" => descending ? query.OrderByDescending(a => a.AppName) : query.OrderBy(a => a.AppName),
            "createdat" => descending ? query.OrderByDescending(a => a.CreatedAt) : query.OrderBy(a => a.CreatedAt),
            "createdby" => descending ? query.OrderByDescending(a => a.CreatedBy) : query.OrderBy(a => a.CreatedBy),
            "isactive" => descending ? query.OrderByDescending(a => a.IsActive) : query.OrderBy(a => a.IsActive),
            "version" => descending ? query.OrderByDescending(a => a.Version) : query.OrderBy(a => a.Version),
            _ => query.OrderBy(a => a.Id)
        };
    }
}