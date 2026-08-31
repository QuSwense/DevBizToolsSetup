/*
    Stored Procedure: usp_CreateRuleContextObject
    Description: Creates a new rule context object with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateRuleContextObject]
    @ContextName NVARCHAR(100),
    @RuleTypeId NVARCHAR(255),
    @Description NVARCHAR(500) = NULL,
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

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Check for duplicate context name
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[RuleContextObjects]
            WHERE [ContextName] = @ContextName
        )
        BEGIN
            RAISERROR('Context object with name "%s" already exists.', 16, 1, @ContextName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new record
        INSERT INTO [dbo].[RuleContextObjects] (
            [ContextName],
            [RuleTypeId],
            [Description],
            [IsActive],
            [CreatedDate],
            [CreatedBy],
            [LastUpdatedDate],
            [LastUpdatedBy]
        )
        VALUES (
            @ContextName,
            @RuleTypeId,
            @Description,
            1,  -- Active by default
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Rule context object created: ', @ContextName, 
                           ' (Type: ', @RuleTypeId, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ContextName AS ContextName,
                @RuleTypeId AS RuleTypeId,
                @Description AS Description
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleContextObjectCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleContextObjects',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS ContextObjectId,
            [ContextName],
            [RuleTypeId],
            [Description],
            [IsActive],
            [CreatedDate],
            [CreatedBy],
            [LastUpdatedDate],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[RuleContextObjects]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating rule context object: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO