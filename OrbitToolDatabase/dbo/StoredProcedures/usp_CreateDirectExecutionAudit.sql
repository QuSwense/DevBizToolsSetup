/*
    Stored Procedure: usp_CreateDirectExecutionAudit
    Description: Creates a new direct execution audit record for tracking SOAP execution runs.
*/
CREATE PROCEDURE [dbo].[usp_CreateDirectExecutionAudit]
    @Name NVARCHAR(200),
    @ExecutedBy NVARCHAR(20) = NULL
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
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @ExecutedBy,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Insert new audit record
        -- Insert new audit record
        INSERT INTO [dbo].[DirectExecutionAudit] (
            [Name],
            [ExecutedAt],
            [ExecutionStatus],
            [ExecutedBy]
        )
        VALUES (
            @Name,
            GETDATE(),
            'InProgress',
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Direct execution audit created: ', @Name);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @NewId AS AuditId,
                @Name AS AuditName,
                'InProgress' AS Status
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
            @ResolvedUser,
            'DirectExecutionAudit',
            'Create',
            @FeatureJson,
            GETDATE()
        );

        SELECT @NewId AS AuditId, @Name AS Name, 'InProgress' AS ExecutionStatus, GETDATE() AS ExecutedAt, @ResolvedUser AS ExecutedBy;

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