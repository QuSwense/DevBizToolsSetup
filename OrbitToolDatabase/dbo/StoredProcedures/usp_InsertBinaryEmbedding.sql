/*
    Stored Procedure: usp_InsertBinaryEmbedding
    Description: Inserts a new binary embedding into the store with deduplication.
    If the same FileHash already exists, returns the existing record.
*/
CREATE PROCEDURE [dbo].[usp_InsertBinaryEmbedding]
    @FileHash VARCHAR(64),
    @CompressedData VARBINARY(MAX),
    @UncompressedSizeBytes INT,
    @CompressionAlgorithmType VARCHAR(50),
    @FileFormat VARCHAR(10) = NULL,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @ExistingId INT;
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Check if the hash already exists
        SELECT @ExistingId = [Id]
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [FileHash] = @FileHash;

        IF @ExistingId IS NOT NULL
        BEGIN
            -- Return existing record
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

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
                0 AS IsNew  -- Indicates this is an existing record
            FROM [dbo].[BinaryEmbeddingsStore]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new record
        INSERT INTO [dbo].[BinaryEmbeddingsStore] (
            [FileHash],
            [CompressedData],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [FileFormat],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @FileHash,
            @CompressedData,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @FileFormat,
            GETDATE(),
            @ResolvedUser,
            NULL,  -- No updates yet
            NULL   -- No updates yet
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Binary embedding stored: ', @FileHash, 
                           ' (Size: ', @UncompressedSizeBytes, ' bytes, Format: ', 
                           ISNULL(@FileFormat, 'Unknown'), ', Compression: ', 
                           @CompressionAlgorithmType, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @FileHash AS FileHash,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @FileFormat AS FileFormat
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'BinaryEmbeddingCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'BinaryEmbeddingsStore',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
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
            1 AS IsNew
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error storing binary embedding: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO