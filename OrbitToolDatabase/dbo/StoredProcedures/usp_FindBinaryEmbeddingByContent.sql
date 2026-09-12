/*
    Stored Procedure: usp_FindBinaryEmbeddingByContent
    Description: Accepts compressed binary data, computes its SHA-256 hash,
    and checks whether matching content already exists in BinaryEmbeddingsStore.
    Useful for comparing response file content against stored embeddings.
*/
CREATE PROCEDURE [dbo].[usp_FindBinaryEmbeddingByContent]
    @CompressedData VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ComputedHash VARCHAR(64);
        DECLARE @ExistingId INT;
        DECLARE @ExistingCompressedData VARBINARY(MAX);
        DECLARE @ContentMatch BIT = 0;

        -- Validate input
        IF @CompressedData IS NULL
        BEGIN
            RAISERROR('@CompressedData must be provided and non-null.', 16, 1);
            RETURN;
        END

        -- Compute SHA-256 hash of the compressed binary content
        SET @ComputedHash = UPPER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedData), 2));

        -- Look up by hash (fast path), then verify content byte-for-byte
        SELECT TOP 1
            @ExistingId = [Id],
            @ExistingCompressedData = [CompressedData]
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [ContentHash] = @ComputedHash;

        IF @ExistingId IS NOT NULL
        BEGIN
            -- Hash matched — verify actual content to guarantee uniqueness
            IF @ExistingCompressedData = @CompressedData
                SET @ContentMatch = 1;
            ELSE
                SET @ExistingId = NULL;  -- Hash collision, treat as not found
        END

        -- Return result
        IF @ContentMatch = 1
        BEGIN
            -- Content exists — return the full record
            SELECT
                [Id] AS EmbeddingId,
                [PublicId],
                [ContentHash],
                [CompressedData],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [ContentFormat],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy],
                1 AS Found,
                0 AS HashCollisionDetected,
                DATALENGTH(@CompressedData) AS DataSizeBytes
            FROM [dbo].[BinaryEmbeddingsStore]
            WHERE [Id] = @ExistingId;
        END
        ELSE
        BEGIN
            -- Content not found (or hash collision) — return computed hash info only
            SELECT
                NULL AS EmbeddingId,
                NULL AS PublicId,
                NULL AS ContentHash,
                NULL AS CompressedData,
                NULL AS UncompressedSizeBytes,
                NULL AS CompressionAlgorithmType,
                NULL AS ContentFormat,
                NULL AS CreatedAt,
                NULL AS CreatedBy,
                NULL AS LastUpdatedAt,
                NULL AS LastUpdatedBy,
                0 AS Found,
                CASE WHEN @ExistingId IS NOT NULL THEN 1 ELSE 0 END AS HashCollisionDetected,
                DATALENGTH(@CompressedData) AS DataSizeBytes;
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error looking up binary embedding by content: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO