/*
    Stored Procedure: usp_UpdateServiceTestSuite
    Description: Updates an existing service test suite with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceTestSuite]
    @TestSuiteId INT,
    @Name NVARCHAR(200) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = NULL,
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
        DECLARE @ExistingName NVARCHAR(200);
        DECLARE @ExistingDescription NVARCHAR(MAX);
        DECLARE @ExistingIsActive BIT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingName = [Name],
            @ExistingDescription = [Description],
            @ExistingIsActive = [IsActive]
        FROM [dbo].[ServiceTestSuites] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @TestSuiteId;

        IF @TestSuiteId IS NULL
        BEGIN
            RAISERROR('Service test suite with Id %d not found.', 16, 1, @TestSuiteId);
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

        -- Check for duplicate name if changed
        IF @Name IS NOT NULL AND @Name <> @ExistingName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceTestSuites]
                WHERE [Name] = @Name
                  AND [Id] != @TestSuiteId
            )
            BEGIN
                RAISERROR('Test suite with name "%s" already exists.', 16, 1, @Name);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[ServiceTestSuites]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [Description] = ISNULL(@Description, [Description]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @TestSuiteId;

        -- Build notes
        SET @Notes = CONCAT('Service test suite updated: ', 
                           ISNULL(@Name, @ExistingName));

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @TestSuiteId AS TestSuiteId,
                ISNULL(@Name, @ExistingName) AS TestSuiteName,
                @Description AS Description,
                @IsActive AS IsActive,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestSuiteUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestSuites',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT 
            [Id] AS TestSuiteId,
            [Name],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestSuites]
        WHERE [Id] = @TestSuiteId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service test suite: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO