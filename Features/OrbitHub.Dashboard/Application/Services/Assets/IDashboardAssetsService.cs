using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Assets;

/// <summary>
/// Provides the managed test assets: request files (SOAP and REST) and WSDL sync records.
/// </summary>
public interface IDashboardAssetsService
{
    /// <summary>
    /// Retrieves all request files (e.g., SOAP envelopes).
    /// </summary>
    Task<IReadOnlyList<RequestFileDto>> GetRequestFilesAsync();

    /// <summary>
    /// Retrieves all REST request files.
    /// </summary>
    Task<IReadOnlyList<RequestFileDto>> GetRestRequestFilesAsync();

    /// <summary>
    /// Retrieves all WSDL sync records.
    /// </summary>
    Task<IReadOnlyList<WsdlRecordDto>> GetWsdlRecordsAsync();
}
