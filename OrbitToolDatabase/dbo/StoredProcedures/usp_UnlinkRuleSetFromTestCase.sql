/*
    Stored Procedure: usp_UnlinkRuleSetFromTestCase
    Description: Removes a link between a rule set and a test case.
*/
CREATE PROCEDURE [dbo].[usp_UnlinkRuleSetFromTestCase]
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
        DECLARE @TestCaseName NVARCHAR(200);
        DECLARE @WorkflowName NVARCHAR(255);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get link details
        SELECT TOP 1
            @TestCaseName = stc.[Name],
            @WorkflowName = rs.[WorkflowName]
        FROM [dbo].[ServiceTestCaseRuleSetLinks] l
        INNER JOIN [dbo].[ServiceTestCases] stc ON l.[ServiceTestCaseId] = stc.[Id]
        INNER JOIN [dbo].[RuleSets] rs ON l.[RuleSetId] = rs.[Id]
        WHERE l.[Id] = @LinkId;

        IF @LinkId IS NULL
        BEGIN
            RAISERROR('Link with Id %d not found.', 16, 1, @LinkId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete the link
        DELETE FROM [dbo].[ServiceTestCaseRuleSetLinks]
        WHERE [Id] = @LinkId;

        -- Build notes
        SET @Notes = CONCAT('Rule set unlinked from test case: ', 
                           @WorkflowName, ' -> ', @TestCaseName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Unlink' AS ChangeType,
                @LinkId AS LinkId,
                @TestCaseName AS TestCaseName,
                @WorkflowName AS WorkflowName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseRuleSetUnlink',
            @ActionType = 'Unlink',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestCases',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT 
            @LinkId AS LinkId,
            'Rule set unlinked successfully' AS Message,
            @ActivityId AS AuditActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error unlinking rule set from test case: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO