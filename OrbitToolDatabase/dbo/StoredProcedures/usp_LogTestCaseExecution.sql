/*
    Stored Procedure: usp_LogTestCaseExecution
    Description: Logs execution of an individual test case within a suite.
*/
CREATE PROCEDURE [dbo].[usp_LogTestCaseExecution]
    @ServiceTestSuiteExecutionAuditId INT,
    @ServiceTestCaseId INT,
    @ServiceResponseFileId INT,
    @HttpStatusCode INT = NULL,
    @HttpVersion NVARCHAR(10) = NULL,
    @HttpRequestDurationMs INT = NULL,
    @HttpRequestHeaders NVARCHAR(MAX) = NULL,
    @HttpResponseHeaders NVARCHAR(MAX) = NULL,
    @HttpContentType NVARCHAR(255) = NULL,
    @HttpContentLength BIGINT = NULL,
    @ExecutionStatus NVARCHAR(50) = 'InProgress',
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
        DECLARE @TestCaseName NVARCHAR(200);
        DECLARE @ResponseFileName NVARCHAR(250);
        DECLARE @AuditSuiteId INT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate Audit exists
        SELECT @AuditSuiteId = [ServiceTestSuiteId]
        FROM [dbo].[ServiceTestSuiteExecutionAudits]
        WHERE [Id] = @ServiceTestSuiteExecutionAuditId;

        IF @AuditSuiteId IS NULL
        BEGIN
            RAISERROR('Test suite execution audit with Id %d not found.', 16, 1, @ServiceTestSuiteExecutionAuditId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate Test Case exists
        SELECT @TestCaseName = [Name]
        FROM [dbo].[ServiceTestCases]
        WHERE [Id] = @ServiceTestCaseId
          AND [IsActive] = 1;

        IF @TestCaseName IS NULL
        BEGIN
            RAISERROR('Test case with Id %d not found or inactive.', 16, 1, @ServiceTestCaseId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate Response File exists
        SELECT @ResponseFileName = [Name]
        FROM [dbo].[ServiceResponseFiles]
        WHERE [Id] = @ServiceResponseFileId
          AND [IsActive] = 1;

        IF @ResponseFileName IS NULL
        BEGIN
            RAISERROR('Service response file with Id %d not found or inactive.', 16, 1, @ServiceResponseFileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert execution record
        INSERT INTO [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] (
            [ServiceTestSuiteExecutionAuditId],
            [ServiceTestCaseId],
            [ServiceResponseFileId],
            [ExecutedAt],
            [ExecutionCompletedAt],
            [HttpStatusCode],
            [HttpVersion],
            [HttpRequestDurationMs],
            [HttpRequestHeaders],
            [HttpResponseHeaders],
            [HttpContentType],
            [HttpContentLength],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy]
        )
        VALUES (
            @ServiceTestSuiteExecutionAuditId,
            @ServiceTestCaseId,
            @ServiceResponseFileId,
            GETDATE(),
            CASE WHEN @ExecutionStatus IN ('Completed', 'Failed') THEN GETDATE() ELSE NULL END,
            @HttpStatusCode,
            @HttpVersion,
            @HttpRequestDurationMs,
            @HttpRequestHeaders,
            @HttpResponseHeaders,
            @HttpContentType,
            @HttpContentLength,
            @ExecutionStatus,
            @ExecutionDetails,
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Test case execution logged: ', @TestCaseName, 
                           ' (Status: ', @ExecutionStatus, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Log' AS ChangeType,
                @ServiceTestSuiteExecutionAuditId AS AuditId,
                @ServiceTestCaseId AS TestCaseId,
                @TestCaseName AS TestCaseName,
                @HttpStatusCode AS HttpStatusCode,
                @ExecutionStatus AS ExecutionStatus,
                @HttpRequestDurationMs AS RequestDurationMs
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'TestCaseExecutionLog',
            @ActionType = 'Log',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS ExecutionLinkId,
            [ServiceTestSuiteExecutionAuditId],
            [ServiceTestCaseId],
            [ServiceResponseFileId],
            [ExecutedAt],
            [ExecutionCompletedAt],
            [HttpStatusCode],
            [HttpVersion],
            [HttpRequestDurationMs],
            [HttpRequestHeaders],
            [HttpResponseHeaders],
            [HttpContentType],
            [HttpContentLength],
            [ExecutionStatus],
            [ExecutionDetails],
            [ExecutedBy],
            @TestCaseName AS TestCaseName,
            @ResponseFileName AS ResponseFileName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error logging test case execution: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO