using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Applications;
using OrbitHub.Data.TestManagement.Views;
using OrbitHub.GenericModels.Enums;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Applications;

/// <summary>
/// Reads the REST and SOAP application catalogs through the generated OrbitHub.Data view repositories.
/// Applications come from v_LatestServiceApplicationsWithAuth and are split by their ServiceType;
/// the API counts come from v_ServiceOperationsSummary.
/// </summary>
internal sealed class DashboardApplicationsRepository(IServiceProvider serviceProvider) : IDashboardApplicationsRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RestAppEntity>> GetRestAppsAsync()
    {
        var (applications, operationsByApp) = await LoadApplicationsAsync();

        return [.. applications
            .Where(a => a.ServiceType.Equals("REST", StringComparison.OrdinalIgnoreCase))
            .Select(a => ToRestEntity(a, operationsByApp))];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SoapAppEntity>> GetSoapAppsAsync()
    {
        var (applications, operationsByApp) = await LoadApplicationsAsync();

        return [.. applications
            .Where(a => a.ServiceType.Equals(EServiceType.SOAP.ToStringCached(), StringComparison.OrdinalIgnoreCase))
            .Select(a => ToSoapEntity(a, operationsByApp))];
    }

    private async Task<(IReadOnlyList<LatestServiceApplicationWithAuthView> Applications, ILookup<string, ServiceOperationsSummaryView> OperationsByApp)> LoadApplicationsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var applicationsView = scope.ServiceProvider.GetRequiredService<LatestServiceApplicationWithAuthViewRepository>();
        var operationsView = scope.ServiceProvider.GetRequiredService<ServiceOperationsSummaryViewRepository>();

        var applications = ViewRepositoryResult.OrThrow(await applicationsView.GetAllAsync());
        var operations = ViewRepositoryResult.OrThrow(await operationsView.GetAllAsync());

        var operationsByApp = operations.ToLookup(o => o.ServicePublicId, StringComparer.OrdinalIgnoreCase);
        return (applications, operationsByApp);
    }

    private static RestAppEntity ToRestEntity(LatestServiceApplicationWithAuthView app, ILookup<string, ServiceOperationsSummaryView> operationsByApp) =>
        new()
        {
            Id = app.ServiceApplicationId,
            Name = app.ServiceApplicationName,
            BaseUrl = app.BaseUrl ?? "",
            Description = app.Description ?? "",
            Status = app.IsActive == true ? "enabled" : "disabled",
            CreatedBy = app.ServiceAppCreatedBy ?? "",
            CreatedAt = app.ServiceAppCreatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "",
            UpdatedAt = app.ServiceAppLastUpdatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "",
            ApisCount = operationsByApp[app.ServiceApplicationId].FirstOrDefault()?.TotalOperations ?? 0
        };

    private static SoapAppEntity ToSoapEntity(LatestServiceApplicationWithAuthView app, ILookup<string, ServiceOperationsSummaryView> operationsByApp) =>
        new()
        {
            Id = app.ServiceApplicationId,
            Name = app.ServiceApplicationName,
            BaseUrl = app.BaseUrl ?? "",
            Description = app.Description ?? "",
            Status = app.IsActive == true ? "enabled" : "disabled",
            CreatedBy = app.ServiceAppCreatedBy ?? "",
            CreatedAt = app.ServiceAppCreatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "",
            UpdatedAt = app.ServiceAppLastUpdatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "",
            ApisCount = operationsByApp[app.ServiceApplicationId].FirstOrDefault()?.TotalOperations ?? 0
        };
}
