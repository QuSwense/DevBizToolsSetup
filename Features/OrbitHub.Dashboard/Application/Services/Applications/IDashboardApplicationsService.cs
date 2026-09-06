using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Applications;

/// <summary>
/// Provides the REST and SOAP application catalogs surfaced on the dashboard.
/// </summary>
public interface IDashboardApplicationsService
{
    /// <summary>
    /// Retrieves all REST applications.
    /// </summary>
    Task<IReadOnlyList<RestAppDto>> GetRestAppsAsync();

    /// <summary>
    /// Retrieves all SOAP applications.
    /// </summary>
    Task<IReadOnlyList<SoapAppDto>> GetSoapAppsAsync();
}
