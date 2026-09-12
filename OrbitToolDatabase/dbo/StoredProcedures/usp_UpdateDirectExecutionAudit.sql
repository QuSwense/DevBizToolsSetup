/*
    Stored Procedure: usp_UpdateDirectExecutionAudit
    Description: Updates an existing direct execution audit record with audit logging.
    Name, ExecutedAt, ExecutedBy, and PublicId are immutable.
*/
CREATE PROCEDURE [dbo].[usp_UpdateDirectExecutionAudit]
    @AuditId INT = NULL,
    @PublicId UNIQUEIDENTIFIER = NULL,
    @ExecutionCompletedAt DATETIME = NULL,
    @ExecutionStatus NVARCHAR(50) = NULL,
    @ExecutionDetails NVARCHAR(MAX) = NULL,
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
        DECLARE @ResolvedId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingName NVARCHAR(200);
        DECLARE @ExistingExecutionStatus NVARCHAR(50);
        DECLARE @ExistingExecutionCompletedAt DATETIME;
        DECLARE @ExistingExecutionDetails NVARCHAR(MAX);
        DECLARE @ExistingPublicId UNIQUEIDENTIFIER;
        DECLARE @StatusChanged BIT = 0;
        DECLARE @DetailsChanged BIT = 0;
        DECLARE @CompletedAtChanged BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Resolve the record by Id or PublicId
        IF @AuditId IS NOT NULL
            SET @ResolvedId = @AuditId;
        ELSE IF @PublicId IS NOT NULL
            SELECT @ResolvedId = [Id] FROM [dbo].[DirectExecutionAudit] WHERE [PublicId] = @PublicId;
        ELSE
        BEGIN
            RAISERROR('Either @AuditId or @PublicId must be provided.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get the current audit details with lock
        SELECT TOP 1
            @ExistingName = [Name],
            @ExistingExecutionStatus = [ExecutionStatus],
            @ExistingExecutionCompletedAt = [ExecutionCompletedAt],
            @ExistingExecutionDetails = [ExecutionDetails],
            @ExistingPublicId = [PublicId]
        FROM [dbo].[DirectExecutionAudit] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @ResolvedId;

        IF @ResolvedId IS NULL OR @ExistingName IS NULL
        BEGIN
            RAISERROR('Direct execution audit not found for the specified identifier.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Detect what changed
        IF @ExecutionStatus IS NOT NULL AND @ExecutionStatus <> @ExistingExecutionStatus
            SET @StatusChanged = 1;

        IF @ExecutionDetails IS NOT NULL AND (@ExecutionDetails <> @ExistingExecutionDetails OR @ExistingExecutionDetails IS NULL)
            SET @DetailsChanged = 1;

        IF @ExecutionCompletedAt IS NOT NULL AND (@ExecutionCompletedAt <> @ExistingExecutionCompletedAt OR @ExistingExecutionCompletedAt IS NULL)
            SET @CompletedAtChanged = 1;

        -- Update the record
        UPDATE [dbo].[DirectExecutionAudit]
        SET
            [ExecutionCompletedAt] = ISNULL(@ExecutionCompletedAt, [ExecutionCompletedAt]),
            [ExecutionStatus] = ISNULL(@ExecutionStatus, [ExecutionStatus]),
            [ExecutionDetails] = ISNULL(@ExecutionDetails, [ExecutionDetails])
        WHERE [Id] = @ResolvedId;

        -- Build notes
        SET @Notes = CONCAT('Direct execution audit updated: ', @ExistingName);
        IF @StatusChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Status: ', @ExistingExecutionStatus, ' -> ', @ExecutionStatus, ')');
        IF @CompletedAtChanged = 1
            SET @Notes = CONCAT(@Notes, ' (CompletedAt updated)');
        IF @DetailsChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Details replaced)');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT
                'Update' AS ChangeType,
                @ExistingName AS ExecutionName,
                @ExecutionStatus AS NewStatus,
                @ExistingExecutionStatus AS PreviousStatus,
                @StatusChanged AS StatusChanged,
                @DetailsChanged AS DetailsChanged,
                @CompletedAtChanged AS CompletedAtChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'DirectExecution',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'DirectExecutionAudit',
            @RelatedEntityId = @ExistingPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
        WHERE [Id] = @ResolvedId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error updating direct execution audit: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO