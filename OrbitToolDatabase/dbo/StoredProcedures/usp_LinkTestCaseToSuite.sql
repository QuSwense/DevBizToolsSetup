/*
    Stored Procedure: usp_LinkTestCaseToSuite
    Description: Links a test case to a test suite with execution order.
*/
CREATE PROCEDURE [dbo].[usp_LinkTestCaseToSuite]
    @ServiceTestSuiteId INT,
    @ServiceTestCaseId INT,
    @ExecutionOrder INT = NULL,
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
        DECLARE @TestCaseName NVARCHAR(200);
        DECLARE @MaxOrder INT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate Suite exists
        SELECT @SuiteName = [Name]
        FROM [dbo].[ServiceTestSuites]
        WHERE [Id] = @ServiceTestSuiteId
          AND [IsActive] = 1;

        IF @SuiteName IS NULL
        BEGIN
            RAISERROR('Test suite with Id %d not found or inactive.', 16, 1, @ServiceTestSuiteId);
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

        -- Check if link already exists
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceTestSuiteTestCaseLinks]
            WHERE [ServiceTestSuiteId] = @ServiceTestSuiteId
              AND [ServiceTestCaseId] = @ServiceTestCaseId
        )
        BEGIN
            RAISERROR('Link already exists between suite "%s" and test case "%s".', 16, 1, @SuiteName, @TestCaseName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Determine execution order
        IF @ExecutionOrder IS NULL
        BEGIN
            SELECT @MaxOrder = ISNULL(MAX([ExecutionOrder]), 0)
            FROM [dbo].[ServiceTestSuiteTestCaseLinks]
            WHERE [ServiceTestSuiteId] = @ServiceTestSuiteId;
            SET @ExecutionOrder = @MaxOrder + 1;
        END

        -- Insert new link
        INSERT INTO [dbo].[ServiceTestSuiteTestCaseLinks] (
            [ServiceTestSuiteId],
            [ServiceTestCaseId],
            [ExecutionOrder],
            [IsActive],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES (
            @ServiceTestSuiteId,
            @ServiceTestCaseId,
            @ExecutionOrder,
            1,  -- Active by default
            GETDATE(),
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Test case linked to suite: ', 
                           @TestCaseName, ' -> ', @SuiteName, 
                           ' (Order: ', @ExecutionOrder, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Link' AS ChangeType,
                @ServiceTestSuiteId AS ServiceTestSuiteId,
                @SuiteName AS SuiteName,
                @ServiceTestCaseId AS ServiceTestCaseId,
                @TestCaseName AS TestCaseName,
                @ExecutionOrder AS ExecutionOrder
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseSuiteLink',
            @ActionType = 'Link',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS LinkId,
            [ServiceTestSuiteId],
            [ServiceTestCaseId],
            [ExecutionOrder],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            @SuiteName AS SuiteName,
            @TestCaseName AS TestCaseName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestSuiteTestCaseLinks]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error linking test case to suite: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO