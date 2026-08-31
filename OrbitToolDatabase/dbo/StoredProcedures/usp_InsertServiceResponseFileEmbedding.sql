/*
    Stored Procedure: usp_InsertServiceResponseFileEmbedding
    Description: Inserts a new service response file embedding record with deduplication.
    Uses BinaryEmbeddingsStore for deduplicated binary storage.
*/
CREATE PROCEDURE [dbo].[usp_InsertServiceResponseFileEmbedding]
    @ServiceResponseFileId INT,
    @CompressedData VARBINARY(MAX),
    @UncompressedSizeBytes INT,
    @CompressionAlgorithmType VARCHAR(50),
    @FileFormat VARCHAR(10) = NULL,
    @Name NVARCHAR(250),
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
        DECLARE @FileHash VARCHAR(64);
        DECLARE @BinaryEmbeddingsStoreId INT;
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ResponseFileName NVARCHAR(250);
        DECLARE @RequestFileName NVARCHAR(250);
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @IsExisting BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Calculate hash
        SET @FileHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedData), 2);

        -- Get response file details
        SELECT 
            @ResponseFileName = srf.[Name],
            @RequestFileName = srf2.[Name],
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceResponseFiles] srf
        INNER JOIN [dbo].[ServiceRequestFiles] srf2 ON srf.[ServiceRequestFileId] = srf2.[Id]
        INNER JOIN [dbo].[ServiceOperations] so ON srf2.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE srf.[Id] = @ServiceResponseFileId
          AND srf.[IsActive] = 1;

        IF @ResponseFileName IS NULL
        BEGIN
            RAISERROR('Service response file with Id %d not found or inactive.', 16, 1, @ServiceResponseFileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert into BinaryEmbeddingsStore (handles deduplication)
        DECLARE @EmbeddingResult TABLE (
            EmbeddingId INT,
            FileHash VARCHAR(64),
            CompressedData VARBINARY(MAX),
            UncompressedSizeBytes INT,
            CompressionAlgorithmType VARCHAR(50),
            FileFormat VARCHAR(10),
            CreatedAt DATETIME,
            CreatedBy NVARCHAR(20),
            LastUpdatedAt DATETIME,
            LastUpdatedBy NVARCHAR(20),
            IsNew BIT
        );

        INSERT INTO @EmbeddingResult
        EXEC [dbo].[usp_InsertBinaryEmbedding]
            @FileHash = @FileHash,
            @CompressedData = @CompressedData,
            @UncompressedSizeBytes = @UncompressedSizeBytes,
            @CompressionAlgorithmType = @CompressionAlgorithmType,
            @FileFormat = @FileFormat,
            @UserId = @ResolvedUser;

        SELECT 
            @BinaryEmbeddingsStoreId = EmbeddingId,
            @IsExisting = CASE WHEN IsNew = 0 THEN 1 ELSE 0 END
        FROM @EmbeddingResult;

        -- Check if embedding already exists for this file
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceResponseFileEmbeddings]
            WHERE [ServiceResponseFileId] = @ServiceResponseFileId
              AND [BinaryEmbeddingsStoreId] = @BinaryEmbeddingsStoreId
        )
        BEGIN
            -- Already linked, return existing
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT 
                [Id] AS EmbeddingId,
                [ServiceResponseFileId],
                [BinaryEmbeddingsStoreId],
                [Name],
                [FileHash],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy],
                0 AS IsNew,
                @IsExisting AS IsExistingEmbedding
            FROM [dbo].[ServiceResponseFileEmbeddings]
            WHERE [ServiceResponseFileId] = @ServiceResponseFileId
              AND [BinaryEmbeddingsStoreId] = @BinaryEmbeddingsStoreId;

            RETURN;
        END

        -- Insert the file embedding link
        INSERT INTO [dbo].[ServiceResponseFileEmbeddings] (
            [ServiceResponseFileId],
            [BinaryEmbeddingsStoreId],
            [Name],
            [FileHash],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @ServiceResponseFileId,
            @BinaryEmbeddingsStoreId,
            @Name,
            @FileHash,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Response file embedding created for: ', @Name, 
                           ' (Response: ', @ResponseFileName, 
                           ', Request: ', @RequestFileName, 
                           ', Operation: ', @OperationName, 
                           ', Service: ', @ServiceName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceResponseFileId AS ServiceResponseFileId,
                @BinaryEmbeddingsStoreId AS BinaryEmbeddingsStoreId,
                @Name AS FileName,
                @FileHash AS FileHash,
                @IsExisting AS WasExistingEmbedding,
                @ResponseFileName AS ResponseFileName,
                @RequestFileName AS RequestFileName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceResponseFileEmbeddingCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS EmbeddingId,
            [ServiceResponseFileId],
            [BinaryEmbeddingsStoreId],
            [Name],
            [FileHash],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            1 AS IsNew,
            @IsExisting AS IsExistingEmbedding
        FROM [dbo].[ServiceResponseFileEmbeddings]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating response file embedding: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO