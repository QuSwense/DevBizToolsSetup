namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the indexing status for request and response file indexing operations.
/// Maps to CK_ServiceRequestIndexingStatus_Status / CK_ServiceResponseIndexingStatus_Status:
/// 'Pending', 'Processing', 'Completed', 'Failed'.
/// </summary>
public enum IndexingStatus
{
    /// <summary>Indexing operation is queued and awaiting processing.</summary>
    Pending = 0,

    /// <summary>Indexing operation is currently in progress.</summary>
    Processing = 1,

    /// <summary>Indexing operation completed successfully.</summary>
    Completed = 2,

    /// <summary>Indexing operation failed.</summary>
    Failed = 3
}
