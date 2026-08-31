/*
    Stored Procedure: usp_LinkRuleSetToContextObject
    Description: Links a rule set to a context object with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_LinkRuleSetToContextObject]
    @RuleSetId INT,
    @RuleContextObjectId INT,
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
        DECLARE @WorkflowName NVARCHAR(255);
        DECLARE @ContextName NVARCHAR(100);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate RuleSet exists
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

        -- Validate ContextObject exists
        SELECT @ContextName = [ContextName]
        FROM [dbo].[RuleContextObjects]
        WHERE [Id] = @RuleContextObjectId
          AND [IsActive] = 1;

        IF @ContextName IS NULL
        BEGIN
            RAISERROR('Context object with Id %d not found or inactive.', 16, 1, @RuleContextObjectId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if link already exists
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[RuleSetContextObjectLinks]
            WHERE [RuleSetId] = @RuleSetId
              AND [RuleContextObjectId] = @RuleContextObjectId
        )
        BEGIN
            RAISERROR('Link already exists between rule set "%s" and context "%s".', 16, 1, @WorkflowName, @ContextName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new link
        INSERT INTO [dbo].[RuleSetContextObjectLinks] (
            [RuleSetId],
            [RuleContextObjectId],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @RuleSetId,
            @RuleContextObjectId,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Rule set linked to context object: ', 
                           @WorkflowName, ' -> ', @ContextName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Link' AS ChangeType,
                @RuleSetId AS RuleSetId,
                @WorkflowName AS WorkflowName,
                @RuleContextObjectId AS RuleContextObjectId,
                @ContextName AS ContextName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleSetContextLinkCreate',
            @ActionType = 'Link',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleSets',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS LinkId,
            [RuleSetId],
            [RuleContextObjectId],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @WorkflowName AS WorkflowName,
            @ContextName AS ContextName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[RuleSetContextObjectLinks]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error linking rule set to context object: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO