/*
    Stored Procedure: usp_UpdateSoapNamespace
    Description: Updates an existing SOAP namespace entry with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateSoapNamespace]
    @NamespaceId INT,
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
        DECLARE @ExistingContent VARBINARY(MAX);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ServiceOperationSchemaId INT;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ContentChanged BIT = 0;
        DECLARE @MetadataChanged BIT = 0;
        DECLARE @CalculatedHash VARCHAR(64);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current namespace details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingContent = [CompressedContent],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType],
            @ExistingContentHash = [ContentHash],
            @ServiceOperationSchemaId = [ServiceOperationSchemaId]
        FROM [dbo].[SoapNamespaces] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @NamespaceId;

        IF @NamespaceId IS NULL
        BEGIN
            RAISERROR('SOAP namespace with Id %d not found.', 16, 1, @NamespaceId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get operation and service details
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceOperationSchemas] sos
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE sos.[Id] = @ServiceOperationSchemaId;

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Detect changes
        IF @CompressedContent IS NOT NULL AND @CompressedContent <> @ExistingContent
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
                [Id] AS NamespaceId,
                [ServiceOperationSchemaId],
                [CompressedContent],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [ContentHash],
                [RecordVersion],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy]
            FROM [dbo].[SoapNamespaces]
            WHERE [Id] = @NamespaceId;
            
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[SoapNamespaces]
        SET
            [CompressedContent] = ISNULL(@CompressedContent, [CompressedContent]),
            [UncompressedSizeBytes] = ISNULL(@UncompressedSizeBytes, [UncompressedSizeBytes]),
            [CompressionAlgorithmType] = ISNULL(@CompressionAlgorithmType, [CompressionAlgorithmType]),
            [ContentHash] = @CalculatedHash,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @NamespaceId;

        -- Build notes
        SET @Notes = CONCAT('SOAP namespace updated for operation: ', @OperationName, 
                           ' (Service: ', @ServiceName, ')');
        IF @ContentChanged = 1
            SET @Notes = CONCAT(@Notes, ' Content changed, Size: ', 
                               ISNULL(CAST(@UncompressedSizeBytes AS NVARCHAR(20)), 'unknown'), ' bytes');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @NamespaceId AS NamespaceId,
                @OperationName AS OperationName,
                @ServiceName AS ServiceName,
                @ServiceAppPublicId AS ServiceId,
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
            @ActivityType = 'SoapNamespaceUpdate',
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
            [Id] AS NamespaceId,
            [ServiceOperationSchemaId],
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
        FROM [dbo].[SoapNamespaces]
        WHERE [Id] = @NamespaceId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating SOAP namespace: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO