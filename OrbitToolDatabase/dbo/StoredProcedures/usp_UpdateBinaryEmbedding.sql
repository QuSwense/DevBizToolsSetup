/*
    Stored Procedure: usp_UpdateBinaryEmbedding
    Description: Updates an existing binary embedding record with audit logging.
    ContentHash is immutable — it is the deduplication key and cannot be changed.
*/
CREATE PROCEDURE [dbo].[usp_UpdateBinaryEmbedding]
    @EmbeddingId INT = NULL,
    @PublicId UNIQUEIDENTIFIER = NULL,
    @CompressedData VARBINARY(MAX) = NULL,
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentFormat VARCHAR(10) = NULL,
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
        DECLARE @ResolvedId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ExistingCompressedData VARBINARY(MAX);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ExistingContentFormat VARCHAR(10);
        DECLARE @ContentChanged BIT = 0;
        DECLARE @MetadataChanged BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Resolve the record by Id or PublicId
        IF @EmbeddingId IS NOT NULL
            SET @ResolvedId = @EmbeddingId;
        ELSE IF @PublicId IS NOT NULL
            SELECT @ResolvedId = [Id] FROM [dbo].[BinaryEmbeddingsStore] WHERE [PublicId] = @PublicId;
        ELSE
        BEGIN
            RAISERROR('Either @EmbeddingId or @PublicId must be provided.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get the current embedding details with lock
        SELECT TOP 1
            @ExistingContentHash = [ContentHash],
            @ExistingCompressedData = [CompressedData],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType],
            @ExistingContentFormat = [ContentFormat]
        FROM [dbo].[BinaryEmbeddingsStore] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @ResolvedId;

        IF @ResolvedId IS NULL OR @ExistingContentHash IS NULL
        BEGIN
            RAISERROR('Binary embedding not found for the specified identifier.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Detect what changed
        IF @CompressedData IS NOT NULL AND @CompressedData <> @ExistingCompressedData
            SET @ContentChanged = 1;

        IF (@UncompressedSizeBytes IS NOT NULL AND @UncompressedSizeBytes <> @ExistingUncompressedSizeBytes)
            OR (@CompressionAlgorithmType IS NOT NULL AND @CompressionAlgorithmType <> @ExistingCompressionAlgorithmType)
            OR (@ContentFormat IS NOT NULL AND @ContentFormat <> @ExistingContentFormat)
            SET @MetadataChanged = 1;

        -- Update the record
        UPDATE [dbo].[BinaryEmbeddingsStore]
        SET
            [CompressedData] = ISNULL(@CompressedData, [CompressedData]),
            [UncompressedSizeBytes] = ISNULL(@UncompressedSizeBytes, [UncompressedSizeBytes]),
            [CompressionAlgorithmType] = ISNULL(@CompressionAlgorithmType, [CompressionAlgorithmType]),
            [ContentFormat] = ISNULL(@ContentFormat, [ContentFormat]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @ResolvedId;

        -- Build notes
        SET @Notes = CONCAT('Binary embedding updated: ', @ExistingContentHash);
        IF @ContentChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Content data replaced)');
        IF @MetadataChanged = 1
        BEGIN
            SET @Notes = CONCAT(@Notes, ' (Metadata: ');
            IF @UncompressedSizeBytes IS NOT NULL AND @UncompressedSizeBytes <> @ExistingUncompressedSizeBytes
                SET @Notes = CONCAT(@Notes, 'Size=', @UncompressedSizeBytes, ' ');
            IF @CompressionAlgorithmType IS NOT NULL AND @CompressionAlgorithmType <> @ExistingCompressionAlgorithmType
                SET @Notes = CONCAT(@Notes, 'Compression=', @CompressionAlgorithmType, ' ');
            IF @ContentFormat IS NOT NULL AND @ContentFormat <> @ExistingContentFormat
                SET @Notes = CONCAT(@Notes, 'Format=', @ContentFormat, ' ');
            SET @Notes = CONCAT(RTRIM(@Notes), ')');
        END

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @ExistingContentHash AS ContentHash,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @ContentFormat AS ContentFormat,
                @ContentChanged AS ContentReplaced
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'BinaryStorage',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'BinaryEmbeddingsStore',
            @RelatedEntityId = @ResolvedId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
            [LastUpdatedBy]
        FROM [dbo].[BinaryEmbeddingsStore]
        WHERE [Id] = @ResolvedId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating binary embedding: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO