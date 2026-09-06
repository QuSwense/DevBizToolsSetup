using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Assets;

/// <summary>
/// Reads the managed test assets: request files (SOAP and REST) and WSDL sync records.
/// </summary>
public interface IDashboardAssetsRepository
{
    /// <summary>
    /// Retrieves all request files (e.g., SOAP envelopes).
    /// </summary>
    Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesAsync();

    /// <summary>
    /// Retrieves all REST request files.
    /// </summary>
    Task<IReadOnlyList<RequestFileEntity>> GetRestRequestFilesAsync();

    /// <summary>
    /// Retrieves all WSDL sync records.
    /// </summary>
    Task<IReadOnlyList<WsdlRecordEntity>> GetWsdlRecordsAsync();
}
