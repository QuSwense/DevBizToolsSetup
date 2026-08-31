/*
    Stored Procedure: usp_GetBinaryEmbeddingUsage
    Description: Gets usage statistics for a binary embedding.
*/
CREATE PROCEDURE [dbo].[usp_GetBinaryEmbeddingUsage]
    @FileHash VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmbeddingId INT;

    SELECT @EmbeddingId = [Id]
    FROM [dbo].[BinaryEmbeddingsStore]
    WHERE [FileHash] = @FileHash;

    IF @EmbeddingId IS NULL
    BEGIN
        SELECT 
            @FileHash AS FileHash,
            0 AS IsUsed,
            0 AS RequestFileCount,
            0 AS ResponseFileCount,
            0 AS RequestEmbeddingCount,
            0 AS ResponseEmbeddingCount;
        RETURN;
    END

    SELECT 
        @FileHash AS FileHash,
        1 AS IsUsed,
        (
            SELECT COUNT(DISTINCT [ServiceRequestFileId])
            FROM [dbo].[ServiceRequestFileEmbeddings] srfe
            WHERE srfe.[BinaryEmbeddingsStoreId] = @EmbeddingId
              AND srfe.[IsActive] = 1
        ) AS RequestFileCount,
        (
            SELECT COUNT(DISTINCT [ServiceResponseFileId])
            FROM [dbo].[ServiceResponseFileEmbeddings] srfe
            WHERE srfe.[BinaryEmbeddingsStoreId] = @EmbeddingId
        ) AS ResponseFileCount,
        (
            SELECT COUNT(*)
            FROM [dbo].[ServiceRequestFileEmbeddings] srfe
            WHERE srfe.[BinaryEmbeddingsStoreId] = @EmbeddingId
              AND srfe.[IsActive] = 1
        ) AS RequestEmbeddingCount,
        (
            SELECT COUNT(*)
            FROM [dbo].[ServiceResponseFileEmbeddings] srfe
            WHERE srfe.[BinaryEmbeddingsStoreId] = @EmbeddingId
        ) AS ResponseEmbeddingCount;
END;
GO