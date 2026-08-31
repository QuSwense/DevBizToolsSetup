/*
    Stored Procedure: usp_UpdateRuleContextObject
    Description: Updates an existing rule context object with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateRuleContextObject]
    @ContextObjectId INT,
    @ContextName NVARCHAR(100) = NULL,
    @RuleTypeId NVARCHAR(255) = NULL,
    @Description NVARCHAR(500) = NULL,
    @IsActive BIT = NULL,
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
        DECLARE @ExistingContextName NVARCHAR(100);
        DECLARE @ExistingRuleTypeId NVARCHAR(255);
        DECLARE @ExistingDescription NVARCHAR(500);
        DECLARE @ExistingIsActive BIT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @ExistingContextName = [ContextName],
            @ExistingRuleTypeId = [RuleTypeId],
            @ExistingDescription = [Description],
            @ExistingIsActive = [IsActive]
        FROM [dbo].[RuleContextObjects] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @ContextObjectId;

        IF @ContextObjectId IS NULL
        BEGIN
            RAISERROR('Rule context object with Id %d not found.', 16, 1, @ContextObjectId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate context name if changed
        IF @ContextName IS NOT NULL AND @ContextName <> @ExistingContextName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[RuleContextObjects]
                WHERE [ContextName] = @ContextName
                  AND [Id] != @ContextObjectId
            )
            BEGIN
                RAISERROR('Context object with name "%s" already exists.', 16, 1, @ContextName);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Update the record
        UPDATE [dbo].[RuleContextObjects]
        SET
            [ContextName] = ISNULL(@ContextName, [ContextName]),
            [RuleTypeId] = ISNULL(@RuleTypeId, [RuleTypeId]),
            [Description] = ISNULL(@Description, [Description]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedDate] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @ContextObjectId;

        -- Build notes
        SET @Notes = CONCAT('Rule context object updated: ', 
                           ISNULL(@ContextName, @ExistingContextName));

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @ContextObjectId AS ContextObjectId,
                ISNULL(@ContextName, @ExistingContextName) AS ContextName,
                @RuleTypeId AS RuleTypeId,
                @Description AS Description,
                @IsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleContextObjectUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleContextObjects',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
        WHERE [Id] = @ContextObjectId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating rule context object: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO