/*
    Stored Procedure: usp_CreateRuleSet
    Description: Creates a new rule set with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateRuleSet]
    @WorkflowName NVARCHAR(255),
    @RuleContent NVARCHAR(MAX),
    @OutputTypeId INT,
    @Description NVARCHAR(500) = NULL,
    @IsActive BIT = 1,
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
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ContextName NVARCHAR(100);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate OutputType exists
        SELECT @ContextName = [ContextName]
        FROM [dbo].[RuleContextObjects]
        WHERE [Id] = @OutputTypeId
          AND [IsActive] = 1;

        IF @ContextName IS NULL
        BEGIN
            RAISERROR('Output type with Id %d not found or inactive.', 16, 1, @OutputTypeId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate workflow name
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[RuleSets]
            WHERE [WorkflowName] = @WorkflowName
        )
        BEGIN
            RAISERROR('Rule set with workflow name "%s" already exists.', 16, 1, @WorkflowName);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate JSON content
        IF ISJSON(@RuleContent) = 0
        BEGIN
            RAISERROR('RuleContent must be valid JSON.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[RuleSets] (
            [WorkflowName],
            [RuleContent],
            [OutputTypeId],
            [IsActive],
            [Description],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @WorkflowName,
            @RuleContent,
            @OutputTypeId,
            @IsActive,
            @Description,
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Rule set created: ', @WorkflowName, 
                           ' (Output Type: ', @ContextName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @WorkflowName AS WorkflowName,
                @OutputTypeId AS OutputTypeId,
                @ContextName AS OutputContextName,
                @Description AS Description,
                @IsActive AS IsActive,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleSetCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleSets',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS RuleSetId,
            [WorkflowName],
            [RuleContent],
            [OutputTypeId],
            [IsActive],
            [Description],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ContextName AS OutputContextName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[RuleSets]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating rule set: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO