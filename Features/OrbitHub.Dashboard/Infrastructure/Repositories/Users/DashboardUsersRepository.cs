using LinqToDB.Async;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.UserManagement;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Users;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Users;

/// <summary>
/// Reads the platform users and their activity feeds from the MSSQL database through linq2db.
/// Registered as a singleton, so every operation opens its own DI scope to obtain a fresh,
/// thread-safe <see cref="UserDbContext"/> (required for the dashboard's parallel fan-out).
/// </summary>
internal sealed class DashboardUsersRepository(IServiceScopeFactory scopeFactory, IConfiguration configuration) : IDashboardUsersRepository
{
    private readonly IServiceScopeFactory _scopeFactory = scopeFactory;
    private readonly IConfiguration _configuration = configuration;

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserEntity>> GetUsersAsync()
    {
        using var userScope = OpenUserContext();

        return [.. (await userScope.Db.Users.ToListAsync())
            .Select(u => new UserEntity
            {
                Name = FormatUserName(u),
                Role = u.RoleId?.ToString() ?? ""
            })];
    }

    /// <inheritdoc />
    public async Task<UserEntity?> GetCurrentUserAsync()
    {
        var currentUserName = _configuration["Users:CurrentUser"];

        if (string.IsNullOrWhiteSpace(currentUserName))
        {
            return null;
        }

        var users = await GetUsersAsync();
        return users.FirstOrDefault(u => u.Name.Equals(currentUserName, StringComparison.OrdinalIgnoreCase));
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserActivityEntity>> GetUserActivitiesAsync()
    {
        using var userScope = OpenUserContext();

        return [.. (await userScope.Db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
            .Select(a => new UserActivityEntity
            {
                Id = a.Id.ToString(),
                UserName = a.UserId,
                Action = a.FeatureActivitiesJson ?? "",
                Timestamp = a.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RecentActivityEntity>> GetRecentActivityAsync()
    {
        using var userScope = OpenUserContext();

        return [.. (await userScope.Db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
            .Select(a => new RecentActivityEntity
            {
                User = a.UserId,
                Action = a.FeatureActivitiesJson ?? "",
                TimeAgo = a.Timestamp.ToString("yyyy-MM-dd HH:mm")
            })];
    }

    /// <summary>
    /// Opens a fresh DI scope and returns a handle exposing the <see cref="UserDbContext" /> resolved from it.
    /// Dispose the handle to release the scope (and its connection). Created per operation so concurrent
    /// dashboard reads never share a single (non-thread-safe) DataConnection.
    /// </summary>
    private UserDbContextScope OpenUserContext() => new(_scopeFactory.CreateScope());

    private static string FormatUserName(User user)
    {
        var fullName = string.Join(" ", new[] { user.FirstName, user.LastName }.Where(s => !string.IsNullOrWhiteSpace(s)));
        return string.IsNullOrWhiteSpace(fullName) ? user.UserId : fullName;
    }

    /// <summary>
    /// Owns a DI scope for the lifetime of a single database operation.
    /// </summary>
    private sealed class UserDbContextScope(IServiceScope scope) : IDisposable
    {
        public UserDbContext Db { get; } = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        public void Dispose() => scope.Dispose();
    }
}
