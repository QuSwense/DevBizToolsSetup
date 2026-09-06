using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Applications;

/// <summary>
/// Reads the REST and SOAP application catalogs surfaced on the dashboard.
/// </summary>
public interface IDashboardApplicationsRepository
{
    /// <summary>
    /// Retrieves all REST applications.
    /// </summary>
    Task<IReadOnlyList<RestAppEntity>> GetRestAppsAsync();

    /// <summary>
    /// Retrieves all SOAP applications.
    /// </summary>
    Task<IReadOnlyList<SoapAppEntity>> GetSoapAppsAsync();
}
