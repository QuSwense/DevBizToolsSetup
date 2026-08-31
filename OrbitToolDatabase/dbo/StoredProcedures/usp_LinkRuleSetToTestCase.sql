/*
    Stored Procedure: usp_LinkRuleSetToTestCase
    Description: Links a rule set to a test case.
*/
CREATE PROCEDURE [dbo].[usp_LinkRuleSetToTestCase]
    @ServiceTestCaseId INT,
    @RuleSetId INT,
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
        DECLARE @WorkflowName NVARCHAR(255);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

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

        -- Validate Rule Set exists
        SELECT @WorkflowName = [WorkflowName]
        FROM [dbo].[RuleSets]
        WHERE [Id] = @RuleSetId
          AND [IsActive] = 1;

        IF @WorkflowName IS NULL
        BEGIN
            RAISERROR('Rule set with Id %d not found or inactive.', 16, 1, @RuleSetId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if link already exists
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceTestCaseRuleSetLinks]
            WHERE [ServiceTestCaseId] = @ServiceTestCaseId
              AND [RuleSetId] = @RuleSetId
        )
        BEGIN
            RAISERROR('Link already exists between test case "%s" and rule set "%s".', 16, 1, @TestCaseName, @WorkflowName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new link
        INSERT INTO [dbo].[ServiceTestCaseRuleSetLinks] (
            [ServiceTestCaseId],
            [RuleSetId],
            [IsActive],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES (
            @ServiceTestCaseId,
            @RuleSetId,
            1,  -- Active by default
            GETDATE(),
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Rule set linked to test case: ', 
                           @WorkflowName, ' -> ', @TestCaseName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Link' AS ChangeType,
                @ServiceTestCaseId AS ServiceTestCaseId,
                @TestCaseName AS TestCaseName,
                @RuleSetId AS RuleSetId,
                @WorkflowName AS WorkflowName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseRuleSetLink',
            @ActionType = 'Link',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestCases',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS LinkId,
            [ServiceTestCaseId],
            [RuleSetId],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            @TestCaseName AS TestCaseName,
            @WorkflowName AS WorkflowName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestCaseRuleSetLinks]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error linking rule set to test case: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO