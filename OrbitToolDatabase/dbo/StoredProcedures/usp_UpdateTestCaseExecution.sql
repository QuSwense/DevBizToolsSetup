/*
    Stored Procedure: usp_UpdateTestCaseExecution
    Description: Updates an existing test case execution record.
*/
CREATE PROCEDURE [dbo].[usp_UpdateTestCaseExecution]
    @ExecutionLinkId INT,
    @HttpStatusCode INT = NULL,
    @HttpRequestDurationMs INT = NULL,
    @HttpResponseHeaders NVARCHAR(MAX) = NULL,
    @HttpContentType NVARCHAR(255) = NULL,
    @HttpContentLength BIGINT = NULL,
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
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @TestCaseName NVARCHAR(200);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get test case name
        SELECT @TestCaseName = stc.[Name]
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] l
        INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
        WHERE l.[Id] = @ExecutionLinkId;

        IF @ExecutionLinkId IS NULL
        BEGIN
            RAISERROR('Execution link with Id %d not found.', 16, 1, @ExecutionLinkId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update the record
        UPDATE [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks]
        SET
            [HttpStatusCode] = ISNULL(@HttpStatusCode, [HttpStatusCode]),
            [HttpRequestDurationMs] = ISNULL(@HttpRequestDurationMs, [HttpRequestDurationMs]),
            [HttpResponseHeaders] = ISNULL(@HttpResponseHeaders, [HttpResponseHeaders]),
            [HttpContentType] = ISNULL(@HttpContentType, [HttpContentType]),
            [HttpContentLength] = ISNULL(@HttpContentLength, [HttpContentLength]),
            [ExecutionStatus] = ISNULL(@ExecutionStatus, [ExecutionStatus]),
            [ExecutionDetails] = ISNULL(@ExecutionDetails, [ExecutionDetails]),
            [ExecutionCompletedAt] = CASE 
                WHEN @ExecutionStatus IN ('Completed', 'Failed') THEN GETDATE() 
                ELSE [ExecutionCompletedAt] 
            END
        WHERE [Id] = @ExecutionLinkId;

        -- Build notes
        SET @Notes = CONCAT('Test case execution updated: ', @TestCaseName, 
                           ' (Status: ', ISNULL(@ExecutionStatus, 'Unknown'), ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @ExecutionLinkId AS ExecutionLinkId,
                @TestCaseName AS TestCaseName,
                @HttpStatusCode AS HttpStatusCode,
                @ExecutionStatus AS ExecutionStatus,
                @HttpRequestDurationMs AS RequestDurationMs
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'TestCaseExecutionUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks]
        WHERE [Id] = @ExecutionLinkId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating test case execution: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO