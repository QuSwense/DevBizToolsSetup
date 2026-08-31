/*
    Stored Procedure: usp_UpdateServiceOperationSchema
    Description: Updates an existing service operation schema with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceOperationSchema]
    @SchemaId INT,
    @InputRootElementName NVARCHAR(200) = NULL,
    @OutputRootElementName NVARCHAR(200) = NULL,
    @TargetNamespace NVARCHAR(500) = NULL,
    @CompressedContent VARBINARY(MAX) = NULL,
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @RecordVersion VARCHAR(50)  -- For optimistic concurrency control
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
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingInputRootElementName NVARCHAR(200);
        DECLARE @ExistingOutputRootElementName NVARCHAR(200);
        DECLARE @ExistingTargetNamespace NVARCHAR(500);
        DECLARE @ExistingCompressedContent VARBINARY(MAX);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ServiceOperationId INT;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ContentChanged BIT = 0;
        DECLARE @MetadataChanged BIT = 0;
        DECLARE @CalculatedHash VARCHAR(64);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current schema details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingInputRootElementName = [InputRootElementName],
            @ExistingOutputRootElementName = [OutputRootElementName],
            @ExistingTargetNamespace = [TargetNamespace],
            @ExistingCompressedContent = [CompressedContent],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType],
            @ExistingContentHash = [ContentHash],
            @ServiceOperationId = [ServiceOperationId]
        FROM [dbo].[ServiceOperationSchemas] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @SchemaId;

        IF @SchemaId IS NULL
        BEGIN
            RAISERROR('Schema with Id %d not found.', 16, 1, @SchemaId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get operation and service details
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceAppPublicId = sa.[PublicId],
            @ServiceAppName = sa.[Name]
        FROM [dbo].[ServiceOperations] so
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE so.[Id] = @ServiceOperationId;

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Detect changes
        IF @InputRootElementName IS NOT NULL AND @InputRootElementName <> @ExistingInputRootElementName
            SET @MetadataChanged = 1;

        IF @OutputRootElementName IS NOT NULL AND @OutputRootElementName <> @ExistingOutputRootElementName
            SET @MetadataChanged = 1;

        IF @TargetNamespace IS NOT NULL AND @TargetNamespace <> @ExistingTargetNamespace
            SET @MetadataChanged = 1;

        IF @CompressedContent IS NOT NULL AND @CompressedContent <> @ExistingCompressedContent
        BEGIN
            SET @ContentChanged = 1;
            
            -- Calculate hash if not provided
            IF @ContentHash IS NULL
            BEGIN
                SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
            END
            ELSE
            BEGIN
                SET @CalculatedHash = @ContentHash;
            END
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ExistingContentHash;
        END

        IF @UncompressedSizeBytes IS NOT NULL AND @UncompressedSizeBytes <> @ExistingUncompressedSizeBytes
            SET @MetadataChanged = 1;

        IF @CompressionAlgorithmType IS NOT NULL AND @CompressionAlgorithmType <> @ExistingCompressionAlgorithmType
            SET @MetadataChanged = 1;

        -- If nothing changed, return existing record
        IF @ContentChanged = 0 AND @MetadataChanged = 0
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT 
                [Id] AS SchemaId,
                [ServiceDefinitionSyncId],
                [ServiceOperationId],
                [InputRootElementName],
                [OutputRootElementName],
                [TargetNamespace],
                [CompressedContent],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [ContentHash],
                [RecordVersion],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy]
            FROM [dbo].[ServiceOperationSchemas]
            WHERE [Id] = @SchemaId;
            
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[ServiceOperationSchemas]
        SET
            [InputRootElementName] = ISNULL(@InputRootElementName, [InputRootElementName]),
            [OutputRootElementName] = ISNULL(@OutputRootElementName, [OutputRootElementName]),
            [TargetNamespace] = ISNULL(@TargetNamespace, [TargetNamespace]),
            [CompressedContent] = ISNULL(@CompressedContent, [CompressedContent]),
            [UncompressedSizeBytes] = ISNULL(@UncompressedSizeBytes, [UncompressedSizeBytes]),
            [CompressionAlgorithmType] = ISNULL(@CompressionAlgorithmType, [CompressionAlgorithmType]),
            [ContentHash] = @CalculatedHash,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @SchemaId;

        -- Build notes
        SET @Notes = CONCAT('Schema updated for operation: ', @OperationName, ' (Service: ', @ServiceAppName, ')');
        IF @ContentChanged = 1
            SET @Notes = CONCAT(@Notes, ' Content changed, Size: ', @UncompressedSizeBytes, ' bytes');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @SchemaId AS SchemaId,
                @OperationName AS OperationName,
                @InputRootElementName AS InputRootElementName,
                @OutputRootElementName AS OutputRootElementName,
                @TargetNamespace AS TargetNamespace,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedHash AS ContentHash,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @ContentChanged AS ContentChanged,
                @MetadataChanged AS MetadataChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceOperationSchemaUpdate',
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
            [Id] AS SchemaId,
            [ServiceDefinitionSyncId],
            [ServiceOperationId],
            [InputRootElementName],
            [OutputRootElementName],
            [TargetNamespace],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceOperationSchemas]
        WHERE [Id] = @SchemaId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service operation schema: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO