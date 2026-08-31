/*
    Stored Procedure: usp_LogRuleExecution
    Description: Logs the execution of a rule set with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_LogRuleExecution]
    @RuleSetId INT,
    @InputCompressedContent VARBINARY(MAX),
    @InputUncompressedSizeBytes INT = NULL,
    @InputContentHash VARCHAR(64) = NULL,
    @OutputCompressedContent VARBINARY(MAX) = NULL,
    @OutputUncompressedSizeBytes INT = NULL,
    @OutputContentHash VARCHAR(64) = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @IsSuccess BIT,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @ExecutionTimeMs INT = NULL,
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
        DECLARE @CalculatedInputHash VARCHAR(64);
        DECLARE @CalculatedOutputHash VARCHAR(64);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate RuleSet exists
        SELECT @WorkflowName = [WorkflowName]
        FROM [dbo].[RuleSets]
        WHERE [Id] = @RuleSetId;

        IF @WorkflowName IS NULL
        BEGIN
            RAISERROR('Rule set with Id %d not found.', 16, 1, @RuleSetId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate input hash if not provided
        IF @InputContentHash IS NULL AND @InputCompressedContent IS NOT NULL
        BEGIN
            SET @CalculatedInputHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @InputCompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedInputHash = @InputContentHash;
        END

        -- Calculate output hash if not provided
        IF @OutputContentHash IS NULL AND @OutputCompressedContent IS NOT NULL
        BEGIN
            SET @CalculatedOutputHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @OutputCompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedOutputHash = @OutputContentHash;
        END

        -- Insert log entry
        INSERT INTO [dbo].[RuleExecutionLogs] (
            [RuleSetId],
            [InputCompressedContent],
            [InputUncompressedSizeBytes],
            [InputContentHash],
            [OutputCompressedContent],
            [OutputUncompressedSizeBytes],
            [OutputContentHash],
            [CompressionAlgorithmType],
            [IsSuccess],
            [ErrorMessage],
            [ExecutionTimeMs],
            [ExecutedAt],
            [ExecutedBy]
        )
        VALUES (
            @RuleSetId,
            @InputCompressedContent,
            @InputUncompressedSizeBytes,
            @CalculatedInputHash,
            @OutputCompressedContent,
            @OutputUncompressedSizeBytes,
            @CalculatedOutputHash,
            @CompressionAlgorithmType,
            @IsSuccess,
            @ErrorMessage,
            @ExecutionTimeMs,
            GETDATE(),
            @ResolvedUser
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Rule execution logged for: ', @WorkflowName, 
                           ' (Success: ', CASE WHEN @IsSuccess = 1 THEN 'Yes' ELSE 'No' END, 
                           ', Time: ', @ExecutionTimeMs, 'ms)');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Execution' AS ChangeType,
                @RuleSetId AS RuleSetId,
                @WorkflowName AS WorkflowName,
                @IsSuccess AS IsSuccess,
                @ExecutionTimeMs AS ExecutionTimeMs,
                @CalculatedInputHash AS InputHash,
                @CalculatedOutputHash AS OutputHash,
                @InputUncompressedSizeBytes AS InputSize,
                @OutputUncompressedSizeBytes AS OutputSize
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RuleExecutionLog',
            @ActionType = 'Execute',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RuleSets',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS LogId,
            [RuleSetId],
            [InputCompressedContent],
            [InputUncompressedSizeBytes],
            [InputContentHash],
            [OutputCompressedContent],
            [OutputUncompressedSizeBytes],
            [OutputContentHash],
            [CompressionAlgorithmType],
            [IsSuccess],
            [ErrorMessage],
            [ExecutionTimeMs],
            [ExecutedAt],
            [ExecutedBy],
            @ActivityId AS AuditActivityId,
            @WorkflowName AS WorkflowName
        FROM [dbo].[RuleExecutionLogs]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @CatchErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error logging rule execution: %s', @ErrorSeverity, @ErrorState, @CatchErrorMessage);
    END CATCH
END;
GO