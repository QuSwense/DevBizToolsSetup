/*
    Stored Procedure: usp_UpdateServiceOperation
    Description: Updates an existing service operation with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceOperation]
    @OperationId INT,
    @OperationName NVARCHAR(200) = NULL,
    @EndpointOrAction NVARCHAR(500) = NULL,
    @HttpMethod VARCHAR(10) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = NULL,
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
        DECLARE @ServiceAppId INT;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingOperationName NVARCHAR(200);
        DECLARE @ExistingEndpointOrAction NVARCHAR(500);
        DECLARE @ExistingHttpMethod VARCHAR(10);
        DECLARE @ExistingDescription NVARCHAR(MAX);
        DECLARE @ExistingIsActive BIT;
        DECLARE @NameChanged BIT = 0;
        DECLARE @DetailsChanged BIT = 0;
        DECLARE @StatusChanged BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current operation details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingOperationName = [OperationName],
            @ExistingEndpointOrAction = [EndpointOrAction],
            @ExistingHttpMethod = [HttpMethod],
            @ExistingDescription = [Description],
            @ExistingIsActive = [IsActive],
            @ServiceAppId = [ServiceApplicationId]
        FROM [dbo].[ServiceOperations] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @OperationId;

        IF @OperationId IS NULL OR @ServiceAppId IS NULL
        BEGIN
            RAISERROR('Service operation with Id %d not found.', 16, 1, @OperationId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get service details for audit
        SELECT 
            @ServiceAppName = [Name],
            @ServiceAppPublicId = [PublicId]
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @ServiceAppId;

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate operation name (if being changed)
        IF @OperationName IS NOT NULL AND @OperationName <> @ExistingOperationName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceOperations] 
                WHERE [ServiceApplicationId] = @ServiceAppId
                  AND [OperationName] = @OperationName
                  AND [Id] != @OperationId
            )
            BEGIN
                RAISERROR('An operation with the name "%s" already exists for this service.', 16, 1, @OperationName);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
            SET @NameChanged = 1;
        END

        -- Detect changes
        IF @EndpointOrAction IS NOT NULL AND @EndpointOrAction <> @ExistingEndpointOrAction
            SET @DetailsChanged = 1;
        
        IF @HttpMethod IS NOT NULL AND @HttpMethod <> @ExistingHttpMethod
            SET @DetailsChanged = 1;
        
        IF @Description IS NOT NULL AND @Description <> @ExistingDescription
            SET @DetailsChanged = 1;

        IF @IsActive IS NOT NULL AND @IsActive <> @ExistingIsActive
            SET @StatusChanged = 1;

        -- If nothing changed, return existing record
        IF @NameChanged = 0 AND @DetailsChanged = 0 AND @StatusChanged = 0
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

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
                [LastUpdatedBy]
            FROM [dbo].[ServiceOperations]
            WHERE [Id] = @OperationId;
            
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[ServiceOperations]
        SET
            [OperationName] = ISNULL(@OperationName, [OperationName]),
            [EndpointOrAction] = ISNULL(@EndpointOrAction, [EndpointOrAction]),
            [HttpMethod] = ISNULL(@HttpMethod, [HttpMethod]),
            [Description] = ISNULL(@Description, [Description]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @OperationId;

        -- Build notes
        SET @Notes = CONCAT('Service operation updated: ', 
            ISNULL(@OperationName, @ExistingOperationName), 
            ' (Service: ', @ServiceAppName, ')');
        
        IF @StatusChanged = 1
        BEGIN
            SET @Notes = CONCAT(@Notes, ' Status: ', 
                CASE WHEN @IsActive = 1 THEN 'Activated' ELSE 'Deactivated' END);
        END

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @OperationId AS OperationId,
                ISNULL(@OperationName, @ExistingOperationName) AS OperationName,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @EndpointOrAction AS EndpointOrAction,
                @HttpMethod AS HttpMethod,
                @IsActive AS IsActive,
                @NameChanged AS NameChanged,
                @DetailsChanged AS DetailsChanged,
                @StatusChanged AS StatusChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceOperationUpdate',
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
        WHERE [Id] = @OperationId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service operation: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO