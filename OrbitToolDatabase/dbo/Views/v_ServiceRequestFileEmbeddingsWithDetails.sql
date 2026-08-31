/*
    View: v_ServiceRequestFileEmbeddingsWithDetails
    Description: Comprehensive view of file embeddings with file details.
*/
CREATE VIEW [dbo].[v_ServiceRequestFileEmbeddingsWithDetails]
AS
SELECT 
    srfe.[Id] AS EmbeddingId,
    srfe.[ServiceRequestFileId],
    srfe.[BinaryEmbeddingsStoreId],
    srfe.[Name] AS EmbeddingName,
    srfe.[FileHash],
    srfe.[IsActive] AS EmbeddingIsActive,
    srfe.[CreatedAt] AS EmbeddingCreatedAt,
    srfe.[CreatedBy] AS EmbeddingCreatedBy,
    srfe.[LastUpdatedAt] AS EmbeddingLastUpdatedAt,
    srfe.[LastUpdatedBy] AS EmbeddingLastUpdatedBy,
    
    -- File details
    srf.[Id] AS FileId,
    srf.[Name] AS FileName,
    srf.[FileFormat],
    srf.[IsBaseSnapshot],
    srf.[DeltaDepth],
    srf.[UncompressedSizeBytes],
    srf.[ContentHash] AS FileContentHash,
    srf.[IsActive] AS FileIsActive,
    
    -- Operation details
    so.[OperationName],
    so.[HttpMethod],
    so.[EndpointOrAction],
    
    -- Service details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
    -- Binary Embeddings Store details (if the table exists)
    bes.[FileHash] AS BinaryFileHash,
    bes.[CompressionAlgorithmType] AS BinaryCompression,
    
    -- Status
    CASE 
        WHEN srfe.[IsActive] = 1 AND srf.[IsActive] = 1 THEN 'Active'
        WHEN srfe.[IsActive] = 0 THEN 'Embedding Inactive'
        ELSE 'File Inactive'
    END AS OverallStatus

FROM [dbo].[ServiceRequestFileEmbeddings] srfe
INNER JOIN [dbo].[ServiceRequestFiles] srf ON srfe.[ServiceRequestFileId] = srf.[Id]
INNER JOIN [dbo].[ServiceOperations] so ON srf.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[BinaryEmbeddingsStore] bes ON srfe.[BinaryEmbeddingsStoreId] = bes.[Id];
GO