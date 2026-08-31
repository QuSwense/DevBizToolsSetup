/*
    Stored Procedure: usp_UnlinkTestCaseFromSuite
    Description: Removes a link between a test case and a test suite.
*/
CREATE PROCEDURE [dbo].[usp_UnlinkTestCaseFromSuite]
    @LinkId INT,
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
        DECLARE @SuiteName NVARCHAR(200);
        DECLARE @TestCaseName NVARCHAR(200);
        DECLARE @ServiceTestSuiteId INT;
        DECLARE @ServiceTestCaseId INT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get link details
        SELECT TOP 1
            @ServiceTestSuiteId = [ServiceTestSuiteId],
            @ServiceTestCaseId = [ServiceTestCaseId],
            @SuiteName = sts.[Name],
            @TestCaseName = stc.[Name]
        FROM [dbo].[ServiceTestSuiteTestCaseLinks] l
        INNER JOIN [dbo].[ServiceTestSuites] sts ON l.[ServiceTestSuiteId] = sts.[Id]
        INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
        WHERE l.[Id] = @LinkId;

        IF @LinkId IS NULL
        BEGIN
            RAISERROR('Link with Id %d not found.', 16, 1, @LinkId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete the link
        DELETE FROM [dbo].[ServiceTestSuiteTestCaseLinks]
        WHERE [Id] = @LinkId;

        -- Build notes
        SET @Notes = CONCAT('Test case unlinked from suite: ', 
                           @TestCaseName, ' -> ', @SuiteName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Unlink' AS ChangeType,
                @LinkId AS LinkId,
                @ServiceTestSuiteId AS ServiceTestSuiteId,
                @SuiteName AS SuiteName,
                @ServiceTestCaseId AS ServiceTestCaseId,
                @TestCaseName AS TestCaseName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseSuiteUnlink',
            @ActionType = 'Unlink',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT 
            @LinkId AS LinkId,
            'Test case unlinked successfully' AS Message,
            @ActivityId AS AuditActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error unlinking test case from suite: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO