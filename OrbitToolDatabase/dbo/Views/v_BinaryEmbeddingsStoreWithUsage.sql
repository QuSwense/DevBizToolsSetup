/*
    View: v_BinaryEmbeddingsStoreWithUsage
    Description: Comprehensive view of binary embeddings with usage statistics.
*/
CREATE VIEW [dbo].[v_BinaryEmbeddingsStoreWithUsage]
AS
SELECT 
    bes.[Id] AS EmbeddingId,
    bes.[FileHash],
    bes.[UncompressedSizeBytes],
    bes.[CompressionAlgorithmType],
    bes.[FileFormat],
    bes.[CreatedAt],
    bes.[CreatedBy],
    bes.[LastUpdatedAt],
    bes.[LastUpdatedBy],
    
    -- Human readable size
    CASE 
        WHEN bes.[UncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(bes.[UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN bes.[UncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(bes.[UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), bes.[UncompressedSizeBytes]) + ' bytes'
    END AS HumanReadableSize,
    
    -- Usage counts
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceRequestFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
          AND srfe.[IsActive] = 1
    ) AS RequestFileEmbeddingCount,
    
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceResponseFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
    ) AS ResponseFileEmbeddingCount,
    
    (
        SELECT COUNT(DISTINCT srfe.[ServiceRequestFileId])
        FROM [dbo].[ServiceRequestFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
          AND srfe.[IsActive] = 1
    ) AS UniqueRequestFiles,
    
    (
        SELECT COUNT(DISTINCT srfe.[ServiceResponseFileId])
        FROM [dbo].[ServiceResponseFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
    ) AS UniqueResponseFiles,
    
    -- Total usage
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceRequestFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
          AND srfe.[IsActive] = 1
    ) + (
        SELECT COUNT(*)
        FROM [dbo].[ServiceResponseFileEmbeddings] srfe
        WHERE srfe.[BinaryEmbeddingsStoreId] = bes.[Id]
    ) AS TotalEmbeddingCount,
    
    -- Hash short
    LEFT(bes.[FileHash], 16) + '...' AS HashShort,
    
    -- Age
    DATEDIFF(DAY, bes.[CreatedAt], GETDATE()) AS AgeDays

FROM [dbo].[BinaryEmbeddingsStore] bes;
GO