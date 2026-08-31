/*
    Stored Procedure: usp_UnlinkRuleSetFromContextObject
    Description: Removes a link between a rule set and a context object with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UnlinkRuleSetFromContextObject]
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
        DECLARE @RuleSetId INT;
        DECLARE @RuleContextObjectId INT;
        DECLARE @WorkflowName NVARCHAR(255);
        DECLARE @ContextName NVARCHAR(100);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get link details
        SELECT TOP 1
            @RuleSetId = [RuleSetId],
            @RuleContextObjectId = [RuleContextObjectId],
            @WorkflowName = rs.[WorkflowName],
            @ContextName = rco.[ContextName]
        FROM [dbo].[RuleSetContextObjectLinks] rl
        INNER JOIN [dbo].[RuleSets] rs ON rl.[RuleSetId] = rs.[Id]
        INNER JOIN [dbo].[RuleContextObjects] rco ON rl.[RuleContextObjectId] = rco.[Id]
        WHERE rl.[Id] = @LinkId;

        IF @LinkId IS NULL
        BEGIN
            RAISERROR('Link with Id %d not found.', 16, 1, @LinkId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete the link
        DELETE FROM [dbo].[RuleSetContextObjectLinks]
        WHERE [Id] = @LinkId;

        -- Build notes
        SET @Notes = CONCAT('Rule set unlinked from context object: ', 
                           @WorkflowName, ' -> ', @ContextName);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Unlink' AS ChangeType,
                @LinkId AS LinkId,
                @RuleSetId AS RuleSetId,
                @WorkflowName AS WorkflowName,
                @RuleContextObjectId AS RuleContextObjectId,
                @ContextName AS ContextName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleSetContextLinkDelete',
            @ActionType = 'Unlink',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleSets',
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
        
        RAISERROR('Error unlinking rule set from context object: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO