/*
    Stored Procedure: usp_CompleteDirectExecutionAudit
    Description: Updates the status and completion timestamp of a direct execution audit.
*/
CREATE PROCEDURE [dbo].[usp_CompleteDirectExecutionAudit]
    @AuditId INT,
    @ExecutionStatus NVARCHAR(50),
    @ExecutionDetails NVARCHAR(MAX) = NULL
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
        DECLARE @ExistingStatus NVARCHAR(50);
        DECLARE @AuditName NVARCHAR(200);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Get current audit details
        SELECT @ExistingStatus = [ExecutionStatus], @AuditName = [Name]
        FROM [dbo].[DirectExecutionAudit]
        WHERE [Id] = @AuditId;

        IF @AuditName IS NULL
        BEGIN
            RAISERROR('Direct execution audit with Id %d not found.', 16, 1, @AuditId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update audit record
        UPDATE [dbo].[DirectExecutionAudit]
        SET
            [ExecutionStatus] = @ExecutionStatus,
            [ExecutionCompletedAt] = GETDATE(),
            [ExecutionDetails] = @ExecutionDetails
        WHERE [Id] = @AuditId;

        -- Build notes
        SET @Notes = CONCAT('Direct execution audit completed: ', @AuditName, ' (Status: ', @ExecutionStatus, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Complete' AS ChangeType,
                @AuditId AS AuditId,
                @AuditName AS AuditName,
                @ExistingStatus AS PreviousStatus,
                @ExecutionStatus AS NewStatus
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        INSERT INTO [dbo].[UserActivities] (
            [UserId],
            [ActivityType],
            [ActionType],
            [FeatureActivitiesJson],
            [Timestamp]
        )
        VALUES (
            'SYSTEM',
            'DirectExecutionAudit',
            'Complete',
            @FeatureJson,
            GETDATE()
        );

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