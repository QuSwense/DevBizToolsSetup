/*
    Stored Procedure: usp_CreateServiceOperationWithSchema
    Description: Creates a new service operation along with optional schema and namespace entries
    in a single transaction. Accepts ServiceApplicationId (int) and resolves internally.
*/
CREATE PROCEDURE [dbo].[usp_CreateServiceOperationWithSchema]
    @ServiceApplicationId INT,
    @OperationName NVARCHAR(200),
    @EndpointOrAction NVARCHAR(500) = NULL,
    @HttpMethod VARCHAR(10) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @InputRootElementName NVARCHAR(200) = NULL,
    @OutputRootElementName NVARCHAR(200) = NULL,
    @TargetNamespace NVARCHAR(500) = NULL,
    @CompressedSchemaContent VARBINARY(MAX) = NULL,
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
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewOpId INT;
        DECLARE @NewSchemaId INT;
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get service application details
        SELECT @ServiceAppPublicId = [PublicId], @ServiceAppName = [Name]
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @ServiceApplicationId AND [IsActive] = 1;

        IF @ServiceAppPublicId IS NULL
        BEGIN
            RAISERROR('Service application with Id %d not found or inactive.', 16, 1, @ServiceApplicationId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate operation name
        IF EXISTS (
            SELECT 1 FROM [dbo].[ServiceOperations]
            WHERE [ServiceApplicationId] = @ServiceApplicationId
              AND [OperationName] = @OperationName
        )
        BEGIN
            RAISERROR('An operation with the name "%s" already exists for this service.', 16, 1, @OperationName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate initial version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert operation
        INSERT INTO [dbo].[ServiceOperations] (
            [ServiceApplicationId], [OperationName], [EndpointOrAction], [HttpMethod],
            [Description], [IsActive], [RecordVersion], [CreatedAt], [CreatedBy],
            [LastUpdatedAt], [LastUpdatedBy]
        )
        VALUES (
            @ServiceApplicationId, @OperationName, @EndpointOrAction, @HttpMethod,
            @Description, 1, @NewRecordVersion, GETDATE(), @ResolvedUser,
            NULL, NULL
        );

        SET @NewOpId = SCOPE_IDENTITY();

        -- Insert schema if any schema data is provided
        IF @InputRootElementName IS NOT NULL OR @OutputRootElementName IS NOT NULL OR @CompressedSchemaContent IS NOT NULL
        BEGIN
            -- Get latest definition sync ID
            DECLARE @SyncId INT;
            SELECT TOP 1 @SyncId = [Id]
            FROM [dbo].[ServiceDefinitionSyncs]
            WHERE [ServiceApplicationId] = @ServiceApplicationId
            ORDER BY [Id] DESC;

            INSERT INTO [dbo].[ServiceOperationSchemas] (
                [ServiceDefinitionSyncId], [ServiceOperationId],
                [InputRootElementName], [OutputRootElementName], [TargetNamespace],
                [CompressedContent], [CompressionAlgorithmType],
                [RecordVersion], [CreatedAt], [CreatedBy]
            )
            VALUES (
                ISNULL(@SyncId, 0), @NewOpId,
                @InputRootElementName, @OutputRootElementName, @TargetNamespace,
                ISNULL(@CompressedSchemaContent, 0x), 'None',
                [dbo].[fn_CalculateVersion](NULL), GETDATE(), @ResolvedUser
            );

            SET @NewSchemaId = SCOPE_IDENTITY();

            -- Insert namespace if target namespace is provided
            IF @TargetNamespace IS NOT NULL
            BEGIN
                INSERT INTO [dbo].[SoapNamespaces] (
                    [ServiceOperationSchemaId],
                    [CompressedContent],
                    [CompressionAlgorithmType],
                    [RecordVersion], [CreatedAt], [CreatedBy]
                )
                VALUES (
                    @NewSchemaId,
                    CAST(CONCAT('tns:', @TargetNamespace) AS VARBINARY(MAX)),
                    'None',
                    [dbo].[fn_CalculateVersion](NULL), GETDATE(), @ResolvedUser
                );
            END
        END

        -- Build notes
        SET @Notes = CONCAT('Service operation created: ', @OperationName, ' (Service: ', @ServiceAppName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @NewOpId AS OperationId,
                @OperationName AS OperationName,
                @ServiceApplicationId AS ServiceApplicationId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        INSERT INTO [dbo].[UserActivities] (
            [UserId], [ActivityType], [ActionType], [FeatureActivitiesJson], [Timestamp]
        )
        VALUES (
            @ResolvedUser, 'ServiceOperation', 'Create', @FeatureJson, GETDATE()
        );

        -- Return the created operation
        SELECT
            [Id], [ServiceApplicationId], [OperationName], [EndpointOrAction],
            [HttpMethod], [Description], [IsActive], [RecordVersion],
            [CreatedAt], [CreatedBy], [LastUpdatedAt], [LastUpdatedBy]
        FROM [dbo].[ServiceOperations]
        WHERE [Id] = @NewOpId;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END;
GO