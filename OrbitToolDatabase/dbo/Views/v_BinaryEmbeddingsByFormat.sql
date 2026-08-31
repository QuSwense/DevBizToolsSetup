/*
    View: v_BinaryEmbeddingsByFormat
    Description: Binary embeddings grouped by file format.
*/
CREATE VIEW [dbo].[v_BinaryEmbeddingsByFormat]
AS
SELECT TOP (100) PERCENT 
    [FileFormat],
    COUNT(*) AS EmbeddingCount,
    SUM([UncompressedSizeBytes]) AS TotalSize,
    AVG([UncompressedSizeBytes]) AS AvgSize,
    MIN([UncompressedSizeBytes]) AS MinSize,
    MAX([UncompressedSizeBytes]) AS MaxSize,
    
    -- Most common compression for this format
    (
        SELECT TOP 1 [CompressionAlgorithmType]
        FROM [dbo].[BinaryEmbeddingsStore] bes2
        WHERE bes2.[FileFormat] = bes.[FileFormat]
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
WHERE [FileFormat] IS NOT NULL
GROUP BY [FileFormat]
ORDER BY EmbeddingCount DESC;
GO