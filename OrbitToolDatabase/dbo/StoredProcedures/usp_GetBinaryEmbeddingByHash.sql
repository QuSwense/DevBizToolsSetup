/*
    Stored Procedure: usp_GetBinaryEmbeddingByHash
    Description: Retrieves a binary embedding by its SHA-256 hash.
*/
CREATE PROCEDURE [dbo].[usp_GetBinaryEmbeddingByHash]
    @FileHash VARCHAR(64),
    @IncludeData BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @IncludeData = 1
    BEGIN
        SELECT 
            [Id] AS EmbeddingId,
            [FileHash],
            [CompressedData],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [FileFormat],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            -- Human readable size
            CASE 
                WHEN [UncompressedSizeBytes] > 1048576 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
                WHEN [UncompressedSizeBytes] > 1024 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
                ELSE 
                    CONVERT(VARCHAR(20), [UncompressedSizeBytes]) + ' bytes'
            END AS HumanReadableSize
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [FileHash] = @FileHash;
    END
    ELSE
    BEGIN
        SELECT 
            [Id] AS EmbeddingId,
            [FileHash],
            CAST(0x AS VARBINARY(1)) AS CompressedData,  -- Placeholder
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [FileFormat],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            CASE 
                WHEN [UncompressedSizeBytes] > 1048576 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
                WHEN [UncompressedSizeBytes] > 1024 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
                ELSE 
                    CONVERT(VARCHAR(20), [UncompressedSizeBytes]) + ' bytes'
            END AS HumanReadableSize
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [FileHash] = @FileHash;
    END
END;
GO