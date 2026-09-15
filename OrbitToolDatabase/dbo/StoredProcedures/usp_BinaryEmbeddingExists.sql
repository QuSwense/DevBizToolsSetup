/*
    Stored Procedure: usp_BinaryEmbeddingExists
    Description: Checks if a binary embedding exists by hash.
*/
CREATE PROCEDURE [dbo].[usp_BinaryEmbeddingExists]
    @ContentHash VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [dbo].[BinaryEmbeddingsStore] 
                WHERE [ContentHash] = @ContentHash
            ) THEN 1
            ELSE 0
        END AS [Exists],
        [Id] AS EmbeddingId
    FROM [dbo].[BinaryEmbeddingsStore]
    WHERE [ContentHash] = @ContentHash;
END;
GO