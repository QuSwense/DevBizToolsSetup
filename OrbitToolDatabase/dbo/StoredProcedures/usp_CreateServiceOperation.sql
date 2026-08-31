/*
    Stored Procedure: usp_CreateServiceOperation
    Description: Creates a new service operation for a service application with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateServiceOperation]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @OperationName NVARCHAR(200),
    @EndpointOrAction NVARCHAR(500) = NULL,
    @HttpMethod VARCHAR(10) = NULL,
    @Description NVARCHAR(MAX) = NULL,
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
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingId INT;

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

        -- Check for duplicate operation name (active only)
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceOperations] 
            WHERE [ServiceApplicationId] = @ServiceAppId
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

        -- Insert new record
        INSERT INTO [dbo].[ServiceOperations] (
            [ServiceApplicationId],
            [OperationName],
            [EndpointOrAction],
            [HttpMethod],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @ServiceAppId,
            @OperationName,
            @EndpointOrAction,
            @HttpMethod,
            @Description,
            1,  -- New records are active by default
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,  -- No updates yet
            NULL   -- No updates yet
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes string
        SET @Notes = CONCAT('New service operation created: ', @OperationName, ' for service: ', @ServiceAppName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @ServiceAppName AS ServiceName,
                @OperationName AS OperationName,
                @EndpointOrAction AS EndpointOrAction,
                @HttpMethod AS HttpMethod,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceOperationCreate',
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
            [Id] AS OperationId,
            [ServiceApplicationId],
            [OperationName],
            [EndpointOrAction],
            [HttpMethod],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceOperations]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating service operation: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO