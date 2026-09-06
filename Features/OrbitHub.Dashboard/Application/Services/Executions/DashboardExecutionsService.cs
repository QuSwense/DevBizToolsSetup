using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Executions;

namespace OrbitHub.Dashboard.Application.Services.Executions;

/// <summary>
/// Provides the request-file execution history by reading from the executions repository.
/// </summary>
internal sealed class DashboardExecutionsService(IDashboardExecutionsRepository repository) : IDashboardExecutionsService
{
    private readonly IDashboardExecutionsRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestExecutionDto>> GetRequestExecutionsAsync()
    {
        var entities = await _repository.GetRequestExecutionsAsync();

        return [.. entities
            .Select(e => new RequestExecutionDto
            {
                Id = e.Id,
                AppName = e.AppName,
                AppType = e.AppType,
                FileName = e.FileName,
                Status = e.Status,
                ExecutedAt = e.ExecutedAt,
                DurationMs = e.DurationMs,
                TriggeredBy = e.TriggeredBy
            })];
    }
}
