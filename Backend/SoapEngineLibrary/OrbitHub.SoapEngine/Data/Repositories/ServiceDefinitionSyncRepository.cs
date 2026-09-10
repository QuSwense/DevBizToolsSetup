namespace OrbitHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using OrbitHub.Data.Common;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.Data.TestManagement.Models;
using OrbitHub.Data.TestManagement.Repositories;
using OrbitHub.SoapEngine.Core.Parsing.Models;

/// <summary>
/// Provides atomic persistence operations for service definition (WSDL) sync snapshots
/// using stored procedure repositories from OrbitHub.Data.
/// </summary>
public class ServiceDefinitionSyncRepository(
    InsertServiceDefinitionSyncRepository insertSyncRepo,
    SaveServiceDefinitionSyncWithOperationsRepository saveSyncWithOpsRepo,
    GetServiceDefinitionSyncLatestVersionRepository getLatestVersionRepo,
    GetServiceDefinitionSyncRepository getSyncRepo,
    UpdateServiceDefinitionSyncRepository updateSyncRepo,
    CreateServiceOperationRepository createOpRepo,
    CreateServiceOperationSchemaRepository createSchemaRepo,
    CreateSoapNamespaceRepository createNsRepo,
    IUnitOfWork unitOfWork,
    ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Atomically persists a new definition sync snapshot along with auto-parsed operations,
    /// XSD schemas, and namespaces via SaveServiceDefinitionSyncWithOperations SP.
    /// </summary>
    public async Task<ServiceDefinitionSync> SaveDefinitionSyncAsync(
        ServiceDefinitionSync definitionSync,
        ParsedWsdlMetadata parsedMetadata,
        string? changeComment = null,
        CancellationToken cancellationToken = default)
    {
        // Use the composite SP that handles sync + ops + schemas + namespaces atomically
        var result = await saveSyncWithOpsRepo.ExecuteAsync(new SaveServiceDefinitionSyncWithOperationsInput
        {
            ServiceApplicationId = definitionSync.ServiceApplicationId,
            DefinitionUrl = definitionSync.DefinitionUrl,
            CompressedContent = definitionSync.CompressedContent,
            UncompressedSizeBytes = definitionSync.UncompressedSizeBytes,
            CompressionAlgorithmType = definitionSync.CompressionAlgorithmType,
            ContentHash = definitionSync.ContentHash,
            UserId = definitionSync.CreatedBy
        }, cancellationToken);

        if (!result.Success || result.Data is null)
            throw new InvalidOperationException($"Failed to save definition sync: {result.ErrorMessage}");

        var dto = result.Data;
        return new ServiceDefinitionSync
        {
            Id = dto.Id,
            ServiceApplicationId = dto.ServiceApplicationId,
            DefinitionUrl = dto.DefinitionUrl,
            CompressedContent = dto.CompressedContent,
            UncompressedSizeBytes = dto.UncompressedSizeBytes,
            CompressionAlgorithmType = dto.CompressionAlgorithmType,
            ContentHash = dto.ContentHash,
            RecordVersion = dto.RecordVersion.ToString(),
            CreatedAt = dto.CreatedAt,
            CreatedBy = dto.CreatedBy,
            LastUpdatedAt = dto.LastUpdatedAt,
            LastUpdatedBy = dto.LastUpdatedBy
        };
    }

    /// <summary>
    /// Fetches the latest active definition sync snapshot for a specific application ID via direct query.
    /// </summary>
    public async Task<ServiceDefinitionSync?> GetLatestByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceDefinitionSyncs
            .Where(w => w.ServiceApplicationId == appId)
            .OrderByDescending(w => w.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a specific definition sync by its primary key identifier via direct query.
    /// </summary>
    public async Task<ServiceDefinitionSync?> GetByIdAsync(int syncId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceDefinitionSyncs
            .FirstOrDefaultAsync(w => w.Id == syncId, cancellationToken);
    }

    /// <summary>
    /// Fetches the latest RecordVersion from definition syncs for an application via SP.
    /// </summary>
    public async Task<string?> GetLatestVersionAsync(int appId, CancellationToken cancellationToken = default)
    {
        var result = await getLatestVersionRepo.ExecuteAsync(
            new GetServiceDefinitionSyncLatestVersionInput { ServiceApplicationId = appId }, cancellationToken);

        if (!result.Success || result.Data is null)
            return null;

        return result.Data.RecordVersion;
    }
}