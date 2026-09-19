/*
    Stored Procedure: usp_SaveBinaryEmbeddingStore

    Content-addressable helper for BinaryEmbeddingStores.
    Because the table has no ContentHash column, the caller must
    supply a stable KeyName that uniquely identifies the binary asset
    (typically derived from SHA-256 of the uncompressed bytes).

    If a row with the same KeyName already exists the existing row is
    returned (WasCreated = 0); otherwise a new row is inserted.
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveBinaryEmbeddingStore]
    @KeyName                    NVARCHAR(255),
    @CompressedData             VARBINARY(MAX),
    @UncompressedSizeBytes      BIGINT,
    @CompressionAlgorithmType   NVARCHAR(50) = NULL,
    @ContentFormat              NVARCHAR(10) = NULL,
    @AdditionalDetails          NVARCHAR(MAX) = NULL,
    @UserId                     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LocalTranStarted BIT = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE
            @ResolvedUser   NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM'),
            @ExistingId     BIGINT,
            @ExistingPublicId UNIQUEIDENTIFIER,
            @NewId          BIGINT,
            @WasCreated     BIT = 0;

        IF NULLIF(LTRIM(RTRIM(@KeyName)), '') IS NULL
            RAISERROR('KeyName is required.', 16, 1);

        IF @CompressedData IS NULL
            RAISERROR('CompressedData is required.', 16, 1);

        IF @UncompressedSizeBytes IS NULL
            RAISERROR('UncompressedSizeBytes is required.', 16, 1);

        IF @CompressionAlgorithmType IS NOT NULL
           AND @CompressionAlgorithmType NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
            RAISERROR('Invalid CompressionAlgorithmType.', 16, 1);

        IF @ContentFormat IS NOT NULL
           AND @ContentFormat NOT IN ('XML', 'JSON', 'PDF', 'BINARY')
            RAISERROR('Invalid ContentFormat.', 16, 1);

        -- Look for existing content by KeyName (content-addressable key)
        SELECT TOP (1)
            @ExistingId       = [Id],
            @ExistingPublicId = [PublicId]
        FROM [dbo].[BinaryEmbeddingStores] WITH (UPDLOCK, HOLDLOCK)
        WHERE [KeyName] = @KeyName
        ORDER BY [Id] DESC;

        IF @ExistingId IS NOT NULL
        BEGIN
            SET @NewId = @ExistingId;
            SET @WasCreated = 0;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[BinaryEmbeddingStores]
            (
                [KeyName],
                [CompressedData],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [ContentFormat],
                [AdditionalDetails],
                [CreatedAt],
                [CreatedBy]
            )
            VALUES
            (
                @KeyName,
                @CompressedData,
                @UncompressedSizeBytes,
                @CompressionAlgorithmType,
                @ContentFormat,
                @AdditionalDetails,
                GETDATE(),
                @ResolvedUser
            );

            SET @NewId = CONVERT(BIGINT, SCOPE_IDENTITY());
            SET @WasCreated = 1;
        END

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id]                        AS BinaryEmbeddingsStoreId,
            [PublicId],
            [KeyName],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentFormat],
            [AdditionalDetails],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @WasCreated                 AS WasCreated,
            CASE WHEN @WasCreated = 1 THEN 'Created' ELSE 'Existing' END AS SaveResult
        FROM [dbo].[BinaryEmbeddingStores]
        WHERE [Id] = @NewId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR('%s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
