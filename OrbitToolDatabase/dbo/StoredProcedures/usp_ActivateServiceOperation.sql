/*
    Stored Procedure: usp_ActivateServiceOperation
    Description: Activates or deactivates a service operation with audit logging.
    Parameters:
        @OperationId INT - Internal Id of the service operation.
        @UserId NVARCHAR(20) - Optional audit user; falls back to SYSTEM_USER.
        @RecordVersion VARCHAR(50) - Current RecordVersion for optimistic concurrency control.
        @IsActive BIT = 1 - 1 to activate (default), 0 to deactivate.
*/
CREATE PROCEDURE [dbo].[usp_ActivateServiceOperation]
    @OperationId INT,
    @UserId NVARCHAR(20) = NULL,
    @RecordVersion VARCHAR(50),  -- For optimistic concurrency control
    @IsActive BIT = 1            -- 1 = activate, 0 = deactivate
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
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingIsActive BIT;
        DECLARE @RequestedStateText NVARCHAR(20);
        DECLARE @ChangeType NVARCHAR(20);
        DECLARE @ActionVerb NVARCHAR(20);
        DECLARE @ActivityTypeName NVARCHAR(100);
        DECLARE @ResultMessage NVARCHAR(100);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Derive state-dependent values once (CASE is not allowed in RAISERROR/EXEC argument lists)
        SET @RequestedStateText = CASE WHEN @IsActive = 1 THEN 'active' ELSE 'inactive' END;
        SET @ChangeType = CASE WHEN @IsActive = 1 THEN 'Activate' ELSE 'Deactivate' END;
        SET @ActionVerb = CASE WHEN @IsActive = 1 THEN 'Reactivated' ELSE 'Deactivated' END;
        SET @ActivityTypeName = CASE WHEN @IsActive = 1 THEN 'ServiceOperationActivate' ELSE 'ServiceOperationDeactivate' END;
        SET @ResultMessage = CASE WHEN @IsActive = 1
            THEN 'Operation reactivated successfully'
            ELSE 'Operation deactivated successfully'
        END;

        -- Get the current operation details with lock
        SELECT TOP 1
            @ExistingRecordVersion = so.[RecordVersion],
            @ExistingIsActive = so.[IsActive],
            @OperationName = so.[OperationName],
            @ServiceAppPublicId = sa.[PublicId],
            @ServiceAppName = sa.[Name]
        FROM [dbo].[ServiceOperations] so WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE so.[Id] = @OperationId;

        IF @ExistingRecordVersion IS NULL
        BEGIN
            RAISERROR('Service operation with Id %d not found.', 16, 1, @OperationId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if already in the requested state
        IF @ExistingIsActive = @IsActive
        BEGIN
            RAISERROR('Operation "%s" is already %s.', 16, 1, @OperationName, @RequestedStateText);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Apply the requested active state
        UPDATE [dbo].[ServiceOperations]
        SET
            [IsActive] = @IsActive,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @OperationId;

        -- Build notes
        SET @Notes = CONCAT('Service operation ',
            CASE WHEN @IsActive = 1 THEN 'reactivated: ' ELSE 'deactivated: ' END,
            @OperationName, ' (Service: ', @ServiceAppName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                @ChangeType AS ChangeType,
                @OperationId AS OperationId,
                @OperationName AS OperationName,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @ExistingIsActive AS OldIsActive,
                @IsActive AS NewIsActive,
                @ActionVerb AS Action
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = @ActivityTypeName,
            @ActionType = @ChangeType,
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return success
        SELECT 
            @OperationId AS OperationId,
            @OperationName AS OperationName,
            @ResultMessage AS Message,
            @ActivityId AS AuditActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error changing service operation active state: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO