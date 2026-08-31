/*
    Stored Procedure: usp_CreateTestSuiteExecutionAudit
    Description: Creates a new test suite execution audit record.
*/
CREATE PROCEDURE [dbo].[usp_CreateTestSuiteExecutionAudit]
    @ServiceTestSuiteId INT,
    @ExecutionStatus NVARCHAR(50) = 'Pending',
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
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @SuiteName NVARCHAR(200);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate Suite exists
        SELECT @SuiteName = [Name]
        FROM [dbo].[ServiceTestSuites]
        WHERE [Id] = @ServiceTestSuiteId;

        IF @SuiteName IS NULL
        BEGIN
            RAISERROR('Test suite with Id %d not found.', 16, 1, @ServiceTestSuiteId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new audit record
        INSERT INTO [dbo].[ServiceTestSuiteExecutionAudits] (
            [ServiceTestSuiteId],
            [ExecutedAt],
            [ExecutionCompletedAt],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy]
        )
        VALUES (
            @ServiceTestSuiteId,
            GETDATE(),
            NULL,
            @ExecutionStatus,
            @ExecutionDetails,
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Test suite execution started: ', @SuiteName, 
                           ' (Status: ', @ExecutionStatus, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceTestSuiteId AS ServiceTestSuiteId,
                @SuiteName AS SuiteName,
                @ExecutionStatus AS ExecutionStatus
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'TestSuiteExecutionCreate',
            @ActionType = 'Execute',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS AuditId,
            [ServiceTestSuiteId],
            [ExecutedAt],
            [ExecutionCompletedAt],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy],
            @SuiteName AS SuiteName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestSuiteExecutionAudits]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating test suite execution audit: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO