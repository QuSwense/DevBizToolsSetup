namespace ServiceHub.SoapEngine.Core.Data.Repositories;

using LinqToDB;
using LinqToDB.Async;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Parsing.Models;

/// <summary>
/// Provides atomic persistence operations for WSDL snapshots, extracted operations, XSD schemas, 
/// and namespaces using LINQ to DB transactions.
/// </summary>
public class SoapWsdlSyncRepository(SoapEngineDataContext context)
{
    private SoapEngineDataContext Context { get; } = context;

    /// <summary>
    /// Atomically persists a new WSDL sync snapshot along with auto-parsed operations, XSD schemas,
    /// namespaces, and audit historical log entries.
    /// </summary>
    public async Task<SoapWsdlSync> SaveWsdlSyncAsync(
        SoapWsdlSync wsdlSync,
        ParsedWsdlMetadata parsedMetadata,
        string? changeComment = null,
        CancellationToken cancellationToken = default)
    {
        await using var transaction = await Context.BeginTransactionAsync(cancellationToken);

        try
        {
            // 1. Insert Parent WSDL Sync Record
            var syncId = await Context.InsertWithInt32IdentityAsync(wsdlSync, token: cancellationToken);
            wsdlSync.Id = syncId;

            // 2. Insert Operations extracted from WSDL
            foreach (var opMetadata in parsedMetadata.Operations)
            {
                var operation = new SoapOperation
                {
                    AppId = wsdlSync.AppId,
                    WsdlSyncId = syncId,
                    OperationName = opMetadata.OperationName,
                    SoapAction = opMetadata.SoapAction,
                    InputRootElementName = opMetadata.InputRootElementName,
                    OutputRootElementName = opMetadata.OutputRootElementName,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = wsdlSync.SyncedBy
                };

                await Context.InsertAsync(operation, token: cancellationToken);
            }

            // 3. Insert Extracted XSD Schemas
            foreach (var xsdContent in parsedMetadata.ExtractedXsdSchemas)
            {
                var schema = new SoapOperationSchema
                {
                    WsdlSyncId = syncId,
                    XsdContent = xsdContent,
                    CreatedAt = DateTime.UtcNow
                };

                await Context.InsertAsync(schema, token: cancellationToken);
            }

            // 4. Insert Extracted WSDL XML Namespaces
            foreach (var (prefix, nsUri) in parsedMetadata.Namespaces)
            {
                var ns = new SoapNamespace
                {
                    WsdlSyncId = syncId,
                    Prefix = string.IsNullOrWhiteSpace(prefix) ? "default" : prefix,
                    NamespaceUri = nsUri,
                    CreatedAt = DateTime.UtcNow
                };

                await Context.InsertAsync(ns, token: cancellationToken);
            }

            // 5. Insert Historical Audit Log
            var historyRecord = new SoapWsdlHistory
            {
                WsdlSyncId = syncId,
                Version = wsdlSync.Version,
                WsdlContent = wsdlSync.WsdlContent,
                SystemLog = $"WSDL synchronized successfully. Parsed {parsedMetadata.Operations.Count} operations.",
                Comment = changeComment,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = wsdlSync.SyncedBy
            };

            await Context.InsertAsync(historyRecord, token: cancellationToken);

            // Commit all atomic inserts
            await transaction.CommitAsync(cancellationToken);

            return wsdlSync;
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    /// <summary>
    /// Fetches the latest active WSDL synchronization snapshot for a specific application ID.
    /// </summary>
    public async Task<SoapWsdlSync?> GetLatestByAppIdAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapWsdlSyncs
            .Where(w => w.AppId == appId)
            .OrderByDescending(w => w.SyncedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <summary>
    /// Retrieves a specific WSDL sync snapshot by its primary key identifier.
    /// </summary>
    public async Task<SoapWsdlSync?> GetByIdAsync(int syncId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapWsdlSyncs
            .FirstOrDefaultAsync(w => w.Id == syncId, cancellationToken);
    }

    /// <summary>
    /// Fetches the latest version string from WSDL synchronizations for an application.
    /// </summary>
    public async Task<string?> GetLatestWsdlVersionAsync(int appId, CancellationToken cancellationToken = default)
    {
        return await Context.SoapWsdlSyncs
            .Where(w => w.AppId == appId)
            .OrderByDescending(w => w.SyncedAt)
            .Select(w => w.Version)
            .FirstOrDefaultAsync(cancellationToken);
    }
}