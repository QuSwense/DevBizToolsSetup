/*
    Stored Procedure: usp_CreateServiceOperationSchema
    Description: Creates a new schema for a service operation with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateServiceOperationSchema]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @OperationName NVARCHAR(200),
    @InputRootElementName NVARCHAR(200) = NULL,
    @OutputRootElementName NVARCHAR(200) = NULL,
    @TargetNamespace NVARCHAR(500) = NULL,
    @CompressedContent VARBINARY(MAX),
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
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
        DECLARE @ServiceAppId INT;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ServiceDefinitionSyncId INT;
        DECLARE @ServiceOperationId INT;
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedHash VARCHAR(64);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the service application details
        SELECT TOP 1
            @ServiceAppId = [Id],
            @ServiceAppName = [Name]
        FROM [dbo].[ServiceApplications]
        WHERE [PublicId] = @ServiceApplicationPublicId
          AND [IsActive] = 1
        ORDER BY [Id] DESC;

        IF @ServiceAppId IS NULL
        BEGIN
            RAISERROR('Service application not found or inactive.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get the operation ID
        SELECT @ServiceOperationId = [Id]
        FROM [dbo].[ServiceOperations]
        WHERE [ServiceApplicationId] = @ServiceAppId
          AND [OperationName] = @OperationName
          AND [IsActive] = 1;

        IF @ServiceOperationId IS NULL
        BEGIN
            RAISERROR('Service operation "%s" not found or inactive.', 16, 1, @OperationName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get the latest definition sync ID for this service
        SELECT TOP 1 @ServiceDefinitionSyncId = [Id]
        FROM [dbo].[ServiceDefinitionSyncs]
        WHERE [ServiceApplicationId] = @ServiceAppId
        ORDER BY [Id] DESC;

        IF @ServiceDefinitionSyncId IS NULL
        BEGIN
            RAISERROR('No definition sync found for this service. Please sync definitions first.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate hash if not provided
        IF @ContentHash IS NULL AND @CompressedContent IS NOT NULL
        BEGIN
            SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ContentHash;
        END

        -- Check if schema already exists for this operation
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceOperationSchemas]
            WHERE [ServiceOperationId] = @ServiceOperationId
        )
        BEGIN
            RAISERROR('A schema already exists for operation "%s". Use update procedure to modify.', 16, 1, @OperationName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate initial version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[ServiceOperationSchemas] (
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
        )
        VALUES (
            @ServiceDefinitionSyncId,
            @ServiceOperationId,
            @InputRootElementName,
            @OutputRootElementName,
            @TargetNamespace,
            @CompressedContent,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @CalculatedHash,
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Schema created for operation: ', @OperationName, 
                           ' (Service: ', @ServiceAppName, ', Size: ', 
                           @UncompressedSizeBytes, ' bytes)');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @ServiceAppName AS ServiceName,
                @OperationName AS OperationName,
                @InputRootElementName AS InputRootElementName,
                @OutputRootElementName AS OutputRootElementName,
                @TargetNamespace AS TargetNamespace,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedHash AS ContentHash,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceOperationSchemaCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceApplicationPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
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
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating service operation schema: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO