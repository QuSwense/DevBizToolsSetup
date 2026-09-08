namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using LinqToDB.Data;
using OrbitHub.Data.ServiceAppManagement;
using ServiceHub.SoapEngine.Core.Parsing.Models;

/// <summary>
/// Provides atomic persistence operations for service definition (WSDL) sync snapshots
/// using the unified ServiceAppDbContext. Stores content as compressed binary.
/// </summary>
public class ServiceDefinitionSyncRepository(ServiceAppDbContext context)
{
    private ServiceAppDbContext Context { get; } = context;

    /// <summary>
    /// Atomically persists a new definition sync snapshot along with auto-parsed operations,
    /// XSD schemas, and namespaces.
    /// </summary>
    public async Task<ServiceDefinitionSync> SaveDefinitionSyncAsync(
        ServiceDefinitionSync definitionSync,
        ParsedWsdlMetadata parsedMetadata,
        string? changeComment = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Insert Parent Definition Sync Record
            definitionSync.RecordVersion = await GetNextVersionAsync(null, cancellationToken);
            definitionSync.CreatedAt = DateTime.UtcNow;

            var syncId = await Context.InsertWithInt32IdentityAsync(definitionSync, token: cancellationToken);
            definitionSync.Id = syncId;

            // 2. Insert Operations extracted from WSDL
            foreach (var opMetadata in parsedMetadata.Operations)
            {
                var operation = new ServiceOperation
                {
                    ServiceApplicationId = definitionSync.ServiceApplicationId,
                    OperationName = opMetadata.OperationName,
                    EndpointOrAction = opMetadata.SoapAction,
                    Description = null,
                    IsActive = true,
                    RecordVersion = await GetNextVersionAsync(null, cancellationToken),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = definitionSync.CreatedBy
                };

                var opId = await Context.InsertWithInt32IdentityAsync(operation, token: cancellationToken);
                operation.Id = opId;

                // Insert schema entry for this operation
                var schema = new ServiceOperationSchema
                {
                    ServiceDefinitionSyncId = syncId,
                    ServiceOperationId = opId,
                    InputRootElementName = opMetadata.InputRootElementName,
                    OutputRootElementName = opMetadata.OutputRootElementName,
                    TargetNamespace = opMetadata.TargetNamespace ?? parsedMetadata.TargetNamespace,
                    CompressedContent = [],
                    CompressionAlgorithmType = "None",
                    RecordVersion = await GetNextVersionAsync(null, cancellationToken),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = definitionSync.CreatedBy
                };
                await Context.InsertAsync(schema, token: cancellationToken);
            }

            // 3. Insert Extracted XSD Schemas (linked to the sync, not to a specific operation)
            foreach (var xsdContent in parsedMetadata.ExtractedXsdSchemas)
            {
                var schema = new ServiceOperationSchema
                {
                    ServiceDefinitionSyncId = syncId,
                    ServiceOperationId = 0, // Not linked to a specific operation
                    CompressedContent = System.Text.Encoding.UTF8.GetBytes(xsdContent),
                    CompressionAlgorithmType = "None",
                    RecordVersion = await GetNextVersionAsync(null, cancellationToken),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = definitionSync.CreatedBy
                };

                await Context.InsertAsync(schema, token: cancellationToken);
            }

            // 4. Insert Extracted WSDL XML Namespaces (linked to schemas)
            var schemasForNs = await Context.ServiceOperationSchemas
                .Where(s => s.ServiceDefinitionSyncId == syncId)
                .ToListAsync(cancellationToken);

            foreach (var (prefix, nsUri) in parsedMetadata.Namespaces)
            {
                foreach (var schemaEntry in schemasForNs)
                {
                    var ns = new OrbitHub.Data.ServiceAppManagement.SoapNamespace
                    {
                        ServiceOperationSchemaId = schemaEntry.Id,
                        CompressedContent = System.Text.Encoding.UTF8.GetBytes($"{prefix}:{nsUri}"),
                        CompressionAlgorithmType = "None",
                        RecordVersion = await GetNextVersionAsync(null, cancellationToken),
                        CreatedAt = DateTime.UtcNow,
                        CreatedBy = definitionSync.CreatedBy
                    };

                    await Context.InsertAsync(ns, token: cancellationToken);
                }
            }

            // Commit all atomic inserts
            await transaction.CommitAsync(cancellationToken);

            return definitionSync;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Fetches the latest active definition sync snapshot for a specific application ID.
    /// </summary>
    public async Task<ServiceDefinitionSync?> GetLatestByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceDefinitionSyncs
            .Where(w => w.ServiceApplicationId == appId)
            .OrderByDescending(w => w.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a specific definition sync by its primary key identifier.
    /// </summary>
    public async Task<ServiceDefinitionSync?> GetByIdAsync(int syncId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceDefinitionSyncs
            .FirstOrDefaultAsync(w => w.Id == syncId, cancellationToken);
    }

    /// <summary>
    /// Fetches the latest RecordVersion from definition syncs for an application.
    /// </summary>
    public async Task<string?> GetLatestVersionAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.ServiceDefinitionSyncs
            .Where(w => w.ServiceApplicationId == appId)
            .OrderByDescending(w => w.CreatedAt)
            .Select(w => w.RecordVersion)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Calls the database function dbo.fn_CalculateVersion to compute the next version string.
    /// </summary>
    private async Task<string> GetNextVersionAsync(string? previousVersion, CancellationToken cancellationToken = default)
    {
        var param = previousVersion is not null
            ? new DataParameter("@PreviousVersion", previousVersion)
            : new DataParameter("@PreviousVersion", DBNull.Value);

        var result = await Context.QueryAsync<string>(
            "SELECT dbo.fn_CalculateVersion(@PreviousVersion)", param);

        return result.FirstOrDefault() ?? "00.00.00";
    }
}