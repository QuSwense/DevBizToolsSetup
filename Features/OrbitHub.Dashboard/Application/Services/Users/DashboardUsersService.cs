using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Users;

namespace OrbitHub.Dashboard.Application.Services.Users;

/// <summary>
/// Provides the platform users and their activity feeds by reading from the users repository.
/// </summary>
internal sealed class DashboardUsersService(IDashboardUsersRepository repository) : IDashboardUsersService
{
    private readonly IDashboardUsersRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserDto>> GetUsersAsync()
    {
        var entities = await _repository.GetUsersAsync();

        return [.. entities
            .Select(e => new UserDto
            {
                Name = e.Name,
                Role = e.Role
            })];
    }

    /// <inheritdoc />
    public async Task<UserDto?> GetCurrentUserAsync()
    {
        var entity = await _repository.GetCurrentUserAsync();

        return entity is null
            ? null
            : new UserDto
            {
                Name = entity.Name,
                Role = entity.Role
            };
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserActivityDto>> GetUserActivitiesAsync()
    {
        var entities = await _repository.GetUserActivitiesAsync();

        return [.. entities
            .Select(e => new UserActivityDto
            {
                Id = e.Id,
                UserName = e.UserName,
                Action = e.Action,
                Timestamp = e.Timestamp
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10)
    {
        var entities = await _repository.GetRecentActivityAsync();

        return [.. entities
            .Select(e => new RecentActivityDto
            {
                User = e.User,
                Action = e.Action,
                TimeAgo = e.TimeAgo
            })
            .Take(maxEntries)];
    }
}
