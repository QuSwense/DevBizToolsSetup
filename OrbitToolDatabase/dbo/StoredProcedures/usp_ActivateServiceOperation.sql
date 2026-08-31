/*
    Stored Procedure: usp_ActivateServiceOperation
    Description: Reactivates a previously deactivated service operation with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_ActivateServiceOperation]
    @OperationId INT,
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
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingIsActive BIT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

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

        IF @OperationId IS NULL
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

        -- Check if already active
        IF @ExistingIsActive = 1
        BEGIN
            RAISERROR('Operation "%s" is already active.', 16, 1, @OperationName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Reactivate by setting IsActive = 1
        UPDATE [dbo].[ServiceOperations]
        SET
            [IsActive] = 1,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @OperationId;

        -- Build notes
        SET @Notes = CONCAT('Service operation reactivated: ', @OperationName, ' (Service: ', @ServiceAppName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Activate' AS ChangeType,
                @OperationId AS OperationId,
                @OperationName AS OperationName,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                'Reactivated' AS Action
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceOperationActivate',
            @ActionType = 'Activate',
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
            'Operation reactivated successfully' AS Message,
            @ActivityId AS AuditActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error reactivating service operation: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO