using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Applications;

namespace OrbitHub.Dashboard.Application.Services.Applications;

/// <summary>
/// Provides the REST and SOAP application catalogs by reading from the applications repository.
/// </summary>
internal sealed class DashboardApplicationsService(IDashboardApplicationsRepository repository) : IDashboardApplicationsService
{
    private readonly IDashboardApplicationsRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RestAppDto>> GetRestAppsAsync()
    {
        var entities = await _repository.GetRestAppsAsync();

        return [.. entities
            .Select(e => new RestAppDto
            {
                Id = e.Id,
                Name = e.Name,
                BaseUrl = e.BaseUrl,
                Description = e.Description,
                Status = e.Status,
                CreatedBy = e.CreatedBy,
                CreatedAt = e.CreatedAt,
                UpdatedAt = e.UpdatedAt,
                ApisCount = e.ApisCount
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SoapAppDto>> GetSoapAppsAsync()
    {
        var entities = await _repository.GetSoapAppsAsync();

        return [.. entities
            .Select(e => new SoapAppDto
            {
                Id = e.Id,
                Name = e.Name,
                BaseUrl = e.BaseUrl,
                Description = e.Description,
                Status = e.Status,
                CreatedBy = e.CreatedBy,
                CreatedAt = e.CreatedAt,
                UpdatedAt = e.UpdatedAt,
                ApisCount = e.ApisCount
            })];
    }
}
