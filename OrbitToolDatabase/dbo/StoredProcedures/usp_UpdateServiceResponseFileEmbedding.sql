/*
    Stored Procedure: usp_UpdateServiceResponseFileEmbedding
    Description: Updates an existing response file embedding record.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceResponseFileEmbedding]
    @EmbeddingId INT,
    @Name NVARCHAR(250) = NULL,
    @FileHash VARCHAR(64) = NULL,
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
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingName NVARCHAR(250);
        DECLARE @ExistingFileHash VARCHAR(64);
        DECLARE @ServiceResponseFileId INT;
        DECLARE @ResponseFileName NVARCHAR(250);
        DECLARE @RequestFileName NVARCHAR(250);
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current embedding details with lock
        SELECT TOP 1
            @ExistingName = [Name],
            @ExistingFileHash = [FileHash],
            @ServiceResponseFileId = [ServiceResponseFileId]
        FROM [dbo].[ServiceResponseFileEmbeddings] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @EmbeddingId;

        IF @EmbeddingId IS NULL
        BEGIN
            RAISERROR('Response file embedding with Id %d not found.', 16, 1, @EmbeddingId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get related details
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
        WHERE srf.[Id] = @ServiceResponseFileId;

        -- Update the record
        UPDATE [dbo].[ServiceResponseFileEmbeddings]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [FileHash] = ISNULL(@FileHash, [FileHash]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @EmbeddingId;

        -- Build notes
        SET @Notes = CONCAT('Response file embedding updated: ', ISNULL(@Name, @ExistingName), 
                           ' (Response: ', @ResponseFileName, 
                           ', Request: ', @RequestFileName, 
                           ', Operation: ', @OperationName, 
                           ', Service: ', @ServiceName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @EmbeddingId AS EmbeddingId,
                ISNULL(@Name, @ExistingName) AS FileName,
                @ExistingFileHash AS OldHash,
                ISNULL(@FileHash, @ExistingFileHash) AS NewHash
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceResponseFileEmbeddingUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceResponseFileEmbeddings]
        WHERE [Id] = @EmbeddingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating response file embedding: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO