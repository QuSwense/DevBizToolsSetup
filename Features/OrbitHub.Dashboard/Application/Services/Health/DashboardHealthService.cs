using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Health;

namespace OrbitHub.Dashboard.Application.Services.Health;

/// <summary>
/// Provides the service health monitoring data by reading from the health repository.
/// </summary>
internal sealed class DashboardHealthService(IDashboardHealthRepository repository) : IDashboardHealthService
{
    private readonly IDashboardHealthRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceHealthDto>> GetServiceHealthAsync()
    {
        var entities = await _repository.GetServiceHealthAsync();

        return [.. entities
            .Select(e => new ServiceHealthDto
            {
                Name = e.Name,
                Status = e.Status.ToString()
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceUptimeDto>> GetServiceUptimeAsync()
    {
        var entities = await _repository.GetServiceUptimeAsync();

        return [.. entities
            .Select(e => new ServiceUptimeDto
            {
                Id = e.Id,
                ServiceName = e.ServiceName,
                Timestamp = e.Timestamp,
                Status = e.Status
            })];
    }
}
