using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.Repositories.TestManagement.Views;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Assets;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Assets;

/// <summary>
/// Reads the managed test assets through the generated OrbitHub.Data view repositories:
/// request files from v_ServiceRequestFilesWithDetails (split by ServiceType) and WSDL
/// sync records rolled up per SOAP application from v_ServiceDefinitionSyncsWithDetails.
/// </summary>
internal sealed class DashboardAssetsRepository(IServiceProvider serviceProvider) : IDashboardAssetsRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <inheritdoc />
    public Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesAsync() =>
        GetRequestFilesByTypeAsync("SOAP");

    /// <inheritdoc />
    public Task<IReadOnlyList<RequestFileEntity>> GetRestRequestFilesAsync() =>
        GetRequestFilesByTypeAsync("REST");

    /// <inheritdoc />
    public async Task<IReadOnlyList<WsdlRecordEntity>> GetWsdlRecordsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var syncsView = scope.ServiceProvider.GetRequiredService<ServiceDefinitionSyncWithDetailsViewRepository>();

        var syncs = ViewRepositoryResult.OrThrow(await syncsView.GetAllAsync());

        // WSDL versions are the per-application definition sync snapshots.
        return [.. syncs
            .Where(s => s.ServiceType.Equals("SOAP", StringComparison.OrdinalIgnoreCase))
            .GroupBy(s => s.ServiceApplicationId)
            .Select(g =>
            {
                var latest = g.OrderByDescending(s => s.SyncCreatedAt ?? DateTime.MinValue).First();
                return new WsdlRecordEntity
                {
                    Id = g.Key.ToString(),
                    AppId = latest.ServicePublicId,
                    AppName = latest.ServiceName,
                    SourceType = latest.DefinitionType ?? "WSDL",
                    UploadedBy = latest.SyncCreatedBy ?? "",
                    UploadedAt = latest.SyncCreatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "",
                    Status = latest.SyncStatus,
                    VersionCount = g.Count()
                };
            })];
    }

    private async Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesByTypeAsync(string serviceType)
    {
        using var scope = _serviceProvider.CreateScope();
        var filesView = scope.ServiceProvider.GetRequiredService<ServiceRequestFileWithDetailsViewRepository>();

        var files = ViewRepositoryResult.OrThrow(await filesView.GetAllAsync());

        return [.. files
            .Where(f => f.ServiceType.Equals(serviceType, StringComparison.OrdinalIgnoreCase))
            .Select(f => new RequestFileEntity
            {
                FileName = f.Name,
                AppName = f.ServiceName,
                Verb = f.HttpMethod ?? (serviceType == "SOAP" ? "POST" : ""),
                Status = f.IsActive ? "active" : "inactive",
                CreatedBy = f.CreatedBy
            })];
    }
}
