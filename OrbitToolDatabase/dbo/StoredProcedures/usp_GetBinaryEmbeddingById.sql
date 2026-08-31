/*
    Stored Procedure: usp_GetBinaryEmbeddingById
    Description: Retrieves a binary embedding by its ID.
*/
CREATE PROCEDURE [dbo].[usp_GetBinaryEmbeddingById]
    @EmbeddingId INT,
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
            CASE 
                WHEN [UncompressedSizeBytes] > 1048576 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
                WHEN [UncompressedSizeBytes] > 1024 THEN 
                    CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
                ELSE 
                    CONVERT(VARCHAR(20), [UncompressedSizeBytes]) + ' bytes'
            END AS HumanReadableSize
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [Id] = @EmbeddingId;
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
        WHERE [Id] = @EmbeddingId;
    END
END;
GO