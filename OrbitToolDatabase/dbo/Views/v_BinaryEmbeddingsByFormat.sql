/*
    View: v_BinaryEmbeddingsByFormat
    Description: Binary embeddings grouped by file format.
*/
CREATE VIEW [dbo].[v_BinaryEmbeddingsByFormat]
AS
SELECT 
    [ContentFormat],
    COUNT(*) AS EmbeddingCount,
    SUM([UncompressedSizeBytes]) AS TotalSize,
    AVG([UncompressedSizeBytes]) AS AvgSize,
    MIN([UncompressedSizeBytes]) AS MinSize,
    MAX([UncompressedSizeBytes]) AS MaxSize,
    
    -- Most common compression for this format
    (
        SELECT TOP 1 [CompressionAlgorithmType]
        FROM [dbo].[BinaryEmbeddingsStore] bes2
        WHERE bes2.[ContentFormat] = bes.[ContentFormat]
        GROUP BY [CompressionAlgorithmType]
        ORDER BY COUNT(*) DESC
    ) AS MostUsedCompression,
    
    -- Human readable sizes
    CASE 
        WHEN SUM([UncompressedSizeBytes]) > 1073741824 THEN 
            CONVERT(VARCHAR(20), CAST(SUM([UncompressedSizeBytes]) / 1073741824.0 AS DECIMAL(10,2))) + ' GB'
        WHEN SUM([UncompressedSizeBytes]) > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(SUM([UncompressedSizeBytes]) / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        ELSE 
            CONVERT(VARCHAR(20), SUM([UncompressedSizeBytes])) + ' bytes'
    END AS TotalSizeHuman

FROM [dbo].[BinaryEmbeddingsStore] bes
WHERE [ContentFormat] IS NOT NULL
GROUP BY [ContentFormat];
GO