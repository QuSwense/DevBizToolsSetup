/*
    Stored Procedure: usp_UpdateServiceRequestFileEmbedding
    Description: Updates an existing file embedding record.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceRequestFileEmbedding]
    @EmbeddingId INT,
    @Name NVARCHAR(250) = NULL,
    @FileHash VARCHAR(64) = NULL,
    @IsActive BIT = NULL,
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
        DECLARE @ExistingIsActive BIT;
        DECLARE @ServiceRequestFileId INT;
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
            @ExistingIsActive = [IsActive],
            @ServiceRequestFileId = [ServiceRequestFileId]
        FROM [dbo].[ServiceRequestFileEmbeddings] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @EmbeddingId;

        IF @EmbeddingId IS NULL
        BEGIN
            RAISERROR('File embedding with Id %d not found.', 16, 1, @EmbeddingId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get operation and service details
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceRequestFiles] srf
        INNER JOIN [dbo].[ServiceOperations] so ON srf.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE srf.[Id] = @ServiceRequestFileId;

        -- Update the record
        UPDATE [dbo].[ServiceRequestFileEmbeddings]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [FileHash] = ISNULL(@FileHash, [FileHash]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @EmbeddingId;

        -- Build notes
        SET @Notes = CONCAT('File embedding updated: ', ISNULL(@Name, @ExistingName), 
                           ' (Operation: ', @OperationName, ', Service: ', @ServiceName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @EmbeddingId AS EmbeddingId,
                ISNULL(@Name, @ExistingName) AS FileName,
                @ExistingIsActive AS OldIsActive,
                ISNULL(@IsActive, @ExistingIsActive) AS NewIsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceRequestFileEmbeddingUpdate',
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
            [ServiceRequestFileId],
            [BinaryEmbeddingsStoreId],
            [Name],
            [FileHash],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceRequestFileEmbeddings]
        WHERE [Id] = @EmbeddingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating file embedding: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO