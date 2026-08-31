/*
    View: v_ServiceResponseFileEmbeddingsWithDetails
    Description: Comprehensive view of response file embeddings with response and request details.
*/
CREATE VIEW [dbo].[v_ServiceResponseFileEmbeddingsWithDetails]
AS
SELECT 
    srfe.[Id] AS EmbeddingId,
    srfe.[ServiceResponseFileId],
    srfe.[BinaryEmbeddingsStoreId],
    srfe.[Name] AS EmbeddingName,
    srfe.[FileHash] AS EmbeddingFileHash,
    srfe.[CreatedAt] AS EmbeddingCreatedAt,
    srfe.[CreatedBy] AS EmbeddingCreatedBy,
    srfe.[LastUpdatedAt] AS EmbeddingLastUpdatedAt,
    srfe.[LastUpdatedBy] AS EmbeddingLastUpdatedBy,
    
    -- Response file details
    srf.[Id] AS ResponseFileId,
    srf.[Name] AS ResponseFileName,
    srf.[FileFormat] AS ResponseFileFormat,
    srf.[IsBaseSnapshot] AS ResponseIsBase,
    srf.[DeltaDepth] AS ResponseDeltaDepth,
    srf.[UncompressedSizeBytes] AS ResponseSize,
    srf.[FileHash] AS ResponseFileHash,
    srf.[IsActive] AS ResponseIsActive,
    
    -- Request file details
    req.[Id] AS RequestFileId,
    req.[Name] AS RequestFileName,
    req.[FileFormat] AS RequestFileFormat,
    
    -- Operation details
    so.[OperationName],
    so.[HttpMethod],
    so.[EndpointOrAction],
    
    -- Service details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
    -- Binary Embeddings Store details
    bes.[FileHash] AS BinaryFileHash,
    bes.[CompressionAlgorithmType] AS BinaryCompression,
    
    -- Status
    CASE 
        WHEN srfe.[Id] IS NOT NULL AND srf.[IsActive] = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS OverallStatus,
    
    -- Pairing info
    CONCAT(req.[Name], ' -> ', srf.[Name], ' -> ', srfe.[Name]) AS FullPath

FROM [dbo].[ServiceResponseFileEmbeddings] srfe
INNER JOIN [dbo].[ServiceResponseFiles] srf ON srfe.[ServiceResponseFileId] = srf.[Id]
INNER JOIN [dbo].[ServiceRequestFiles] req ON srf.[ServiceRequestFileId] = req.[Id]
INNER JOIN [dbo].[ServiceOperations] so ON req.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[BinaryEmbeddingsStore] bes ON srfe.[BinaryEmbeddingsStoreId] = bes.[Id];
GO