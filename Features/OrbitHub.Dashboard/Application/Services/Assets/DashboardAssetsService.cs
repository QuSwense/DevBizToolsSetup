using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Assets;

namespace OrbitHub.Dashboard.Application.Services.Assets;

/// <summary>
/// Provides the managed test assets by reading from the assets repository.
/// </summary>
internal sealed class DashboardAssetsService(IDashboardAssetsRepository repository) : IDashboardAssetsService
{
    private readonly IDashboardAssetsRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileDto>> GetRequestFilesAsync()
    {
        var entities = await _repository.GetRequestFilesAsync();

        return [.. entities
            .Select(e => new RequestFileDto
            {
                FileName = e.FileName,
                AppName = e.AppName,
                Verb = e.Verb,
                Status = e.Status,
                CreatedBy = e.CreatedBy
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileDto>> GetRestRequestFilesAsync()
    {
        var entities = await _repository.GetRestRequestFilesAsync();

        return [.. entities
            .Select(e => new RequestFileDto
            {
                FileName = e.FileName,
                AppName = e.AppName,
                Verb = e.Verb,
                Status = e.Status,
                CreatedBy = e.CreatedBy
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<WsdlRecordDto>> GetWsdlRecordsAsync()
    {
        var entities = await _repository.GetWsdlRecordsAsync();

        return [.. entities
            .Select(e => new WsdlRecordDto
            {
                AppName = e.AppName,
                SourceType = e.SourceType,
                UploadedAt = e.UploadedAt,
                Status = e.Status,
                VersionCount = e.VersionCount
            })];
    }
}
