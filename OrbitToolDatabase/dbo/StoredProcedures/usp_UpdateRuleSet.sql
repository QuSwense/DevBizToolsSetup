/*
    Stored Procedure: usp_UpdateRuleSet
    Description: Updates an existing rule set with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateRuleSet]
    @RuleSetId INT,
    @WorkflowName NVARCHAR(255) = NULL,
    @RuleContent NVARCHAR(MAX) = NULL,
    @OutputTypeId INT = NULL,
    @IsActive BIT = NULL,
    @Description NVARCHAR(500) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @RecordVersion VARCHAR(50)  -- For optimistic concurrency control
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
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingWorkflowName NVARCHAR(255);
        DECLARE @ExistingOutputTypeId INT;
        DECLARE @ExistingIsActive BIT;
        DECLARE @ExistingDescription NVARCHAR(500);
        DECLARE @ExistingRuleContent NVARCHAR(MAX);
        DECLARE @ContextName NVARCHAR(100);
        DECLARE @OutputTypeChanged BIT = 0;
        DECLARE @ContentChanged BIT = 0;
        DECLARE @NameChanged BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingWorkflowName = [WorkflowName],
            @ExistingOutputTypeId = [OutputTypeId],
            @ExistingIsActive = [IsActive],
            @ExistingDescription = [Description],
            @ExistingRuleContent = [RuleContent]
        FROM [dbo].[RuleSets] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @RuleSetId;

        IF @RuleSetId IS NULL
        BEGIN
            RAISERROR('Rule set with Id %d not found.', 16, 1, @RuleSetId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate OutputType if changed
        IF @OutputTypeId IS NOT NULL AND @OutputTypeId <> @ExistingOutputTypeId
        BEGIN
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
            SET @OutputTypeChanged = 1;
        END
        ELSE IF @OutputTypeId IS NOT NULL
        BEGIN
            SELECT @ContextName = [ContextName]
            FROM [dbo].[RuleContextObjects]
            WHERE [Id] = @OutputTypeId;
        END

        -- Check for duplicate workflow name if changed
        IF @WorkflowName IS NOT NULL AND @WorkflowName <> @ExistingWorkflowName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[RuleSets]
                WHERE [WorkflowName] = @WorkflowName
                  AND [Id] != @RuleSetId
            )
            BEGIN
                RAISERROR('Rule set with workflow name "%s" already exists.', 16, 1, @WorkflowName);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
            SET @NameChanged = 1;
        END

        -- Validate JSON content if changed
        IF @RuleContent IS NOT NULL AND @RuleContent <> @ExistingRuleContent
        BEGIN
            IF ISJSON(@RuleContent) = 0
            BEGIN
                RAISERROR('RuleContent must be valid JSON.', 16, 1);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
            SET @ContentChanged = 1;
        END

        -- Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[RuleSets]
        SET
            [WorkflowName] = ISNULL(@WorkflowName, [WorkflowName]),
            [RuleContent] = ISNULL(@RuleContent, [RuleContent]),
            [OutputTypeId] = ISNULL(@OutputTypeId, [OutputTypeId]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [Description] = ISNULL(@Description, [Description]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @RuleSetId;

        -- Build notes
        SET @Notes = CONCAT('Rule set updated: ', 
                           ISNULL(@WorkflowName, @ExistingWorkflowName));
        IF @OutputTypeChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Output Type: ', @ContextName, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @RuleSetId AS RuleSetId,
                ISNULL(@WorkflowName, @ExistingWorkflowName) AS WorkflowName,
                @OutputTypeId AS OutputTypeId,
                @ContextName AS OutputContextName,
                @IsActive AS IsActive,
                @Description AS Description,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @ContentChanged AS ContentChanged,
                @OutputTypeChanged AS OutputTypeChanged,
                @NameChanged AS NameChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleSetUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleSets',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
        WHERE [Id] = @RuleSetId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating rule set: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO