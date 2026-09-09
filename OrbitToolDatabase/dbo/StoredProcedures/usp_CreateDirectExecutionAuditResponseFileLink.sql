/*
    Stored Procedure: usp_CreateDirectExecutionAuditResponseFileLink
    Description: Creates a new response file link record for a direct execution audit.
*/
CREATE PROCEDURE [dbo].[usp_CreateDirectExecutionAuditResponseFileLink]
    @DirectExecutionAuditId INT,
    @ServiceRequestFileId INT,
    @ExecutionOrder INT = 0,
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

        -- Validate audit exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[DirectExecutionAudits] WHERE [Id] = @DirectExecutionAuditId)
        BEGIN
            RAISERROR('Direct execution audit with Id %d not found.', 16, 1, @DirectExecutionAuditId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate request file exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceRequestFiles] WHERE [Id] = @ServiceRequestFileId AND [IsActive] = 1)
        BEGIN
            RAISERROR('Service request file with Id %d not found or inactive.', 16, 1, @ServiceRequestFileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert link record
        INSERT INTO [dbo].[DirectExecutionAuditResponseFileLinks] (
            [DirectExecutionAuditId],
            [ServiceRequestFileId],
            [ExecutionOrder],
            [ExecutionStatus],
            [ExecutedAt]
        )
        VALUES (
            @DirectExecutionAuditId,
            @ServiceRequestFileId,
            @ExecutionOrder,
            'Pending',
            GETDATE()
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Response file link created for audit ID ', @DirectExecutionAuditId);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @NewId AS LinkId,
                @DirectExecutionAuditId AS AuditId,
                @ServiceRequestFileId AS RequestFileId
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
            'DirectExecutionAuditResponseFileLink',
            'Create',
            @FeatureJson,
            GETDATE()
        );

        SELECT @NewId AS Id, @DirectExecutionAuditId AS DirectExecutionAuditId, @ServiceRequestFileId AS ServiceRequestFileId, @ExecutionOrder AS ExecutionOrder, 'Pending' AS ExecutionStatus, GETDATE() AS ExecutedAt;

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