using LinqToDB.Async;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.UserManagement;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Users;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Users;

/// <summary>
/// Reads the platform users and their activity feeds from the MSSQL database through linq2db.
/// </summary>
internal sealed class DashboardUsersRepository(IServiceProvider serviceProvider, IConfiguration configuration) : IDashboardUsersRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private readonly IConfiguration _configuration = configuration;

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserEntity>> GetUsersAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.Users.ToListAsync())
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
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
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
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
            .Select(a => new RecentActivityEntity
            {
                User = a.UserId,
                Action = a.FeatureActivitiesJson ?? "",
                TimeAgo = a.Timestamp.ToString("yyyy-MM-dd HH:mm")
            })];
    }

    private static string FormatUserName(User user)
    {
        var fullName = string.Join(" ", new[] { user.FirstName, user.LastName }.Where(s => !string.IsNullOrWhiteSpace(s)));
        return string.IsNullOrWhiteSpace(fullName) ? user.UserId : fullName;
    }
}
