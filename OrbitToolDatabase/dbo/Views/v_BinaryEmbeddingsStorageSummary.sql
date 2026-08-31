/*
    View: v_BinaryEmbeddingsStorageSummary
    Description: Summary of storage usage for binary embeddings.
*/
CREATE VIEW [dbo].[v_BinaryEmbeddingsStorageSummary]
AS
SELECT 
    COUNT(*) AS TotalEmbeddings,
    SUM([UncompressedSizeBytes]) AS TotalUncompressedSize,
    SUM(DATALENGTH([CompressedData])) AS TotalCompressedSize,
    SUM([UncompressedSizeBytes]) - SUM(DATALENGTH([CompressedData])) AS TotalCompressionSavings,
    
    -- Compression savings percentage
    CASE 
        WHEN SUM([UncompressedSizeBytes]) > 0 THEN
            CAST(
                (SUM([UncompressedSizeBytes]) - SUM(DATALENGTH([CompressedData]))) * 100.0 
                / SUM([UncompressedSizeBytes])
                AS DECIMAL(10,2)
            )
        ELSE 0
    END AS CompressionSavingsPercent,
    
    -- By compression algorithm
    COUNT(DISTINCT [CompressionAlgorithmType]) AS CompressionTypesUsed,
    
    -- By file format
    COUNT(DISTINCT [FileFormat]) AS FileFormatsUsed,
    
    -- Min/Max/Avg sizes
    MIN([UncompressedSizeBytes]) AS MinSize,
    MAX([UncompressedSizeBytes]) AS MaxSize,
    AVG([UncompressedSizeBytes]) AS AvgSize,
    
    -- Human readable totals
    CASE 
        WHEN SUM([UncompressedSizeBytes]) > 1073741824 THEN 
            CONVERT(VARCHAR(20), CAST(SUM([UncompressedSizeBytes]) / 1073741824.0 AS DECIMAL(10,2))) + ' GB'
        WHEN SUM([UncompressedSizeBytes]) > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(SUM([UncompressedSizeBytes]) / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        ELSE 
            CONVERT(VARCHAR(20), SUM([UncompressedSizeBytes])) + ' bytes'
    END AS TotalUncompressedSizeHuman,
    
    CASE 
        WHEN SUM(DATALENGTH([CompressedData])) > 1073741824 THEN 
            CONVERT(VARCHAR(20), CAST(SUM(DATALENGTH([CompressedData])) / 1073741824.0 AS DECIMAL(10,2))) + ' GB'
        WHEN SUM(DATALENGTH([CompressedData])) > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(SUM(DATALENGTH([CompressedData])) / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        ELSE 
            CONVERT(VARCHAR(20), SUM(DATALENGTH([CompressedData]))) + ' bytes'
    END AS TotalCompressedSizeHuman

FROM [dbo].[BinaryEmbeddingsStore];
GO