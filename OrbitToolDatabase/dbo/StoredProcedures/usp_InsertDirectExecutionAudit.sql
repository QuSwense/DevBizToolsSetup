/*
    Stored Procedure: usp_InsertDirectExecutionAudit
    Description: Inserts a new direct execution audit log entry.
    Each execution is logged as a new entry — no deduplication.
*/
CREATE PROCEDURE [dbo].[usp_InsertDirectExecutionAudit]
    @Name NVARCHAR(200),
    @ExecutionStatus NVARCHAR(50),
    @ExecutionDetails NVARCHAR(MAX) = NULL,
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
        DECLARE @NewPublicId UNIQUEIDENTIFIER;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @ExecutedBy,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Insert new record
        INSERT INTO [dbo].[DirectExecutionAudit] (
            [Name],
            [ExecutedAt],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy]
        )
        VALUES (
            @Name,
            GETDATE(),
            @ExecutionStatus,
            @ExecutionDetails,
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        SELECT @NewPublicId = [PublicId]
        FROM [dbo].[DirectExecutionAudit]
        WHERE [Id] = @NewId;

        -- Build notes
        SET @Notes = CONCAT('Direct execution logged: ', @Name,
                           ' (Status: ', @ExecutionStatus, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT
                'Insert' AS ChangeType,
                @Name AS ExecutionName,
                @ExecutionStatus AS ExecutionStatus,
                @ExecutionDetails AS ExecutionDetails
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'DirectExecution',
            @ActionType = 'Insert',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'DirectExecutionAudit',
            @RelatedEntityId = @NewPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT
            [Id] AS AuditId,
            [PublicId],
            [Name],
            [ExecutedAt],
            [ExecutionCompletedAt],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy]
        FROM [dbo].[DirectExecutionAudit]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error inserting direct execution audit: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO