/*
    Stored Procedure: usp_UpdateServiceTestCase
    Description: Updates an existing service test case with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceTestCase]
    @TestCaseId INT,
    @Name NVARCHAR(200) = NULL,
    @ServiceRequestFileId INT = NULL,
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
        DECLARE @ExistingServiceRequestFileId INT;
        DECLARE @ExistingIsActive BIT;
        DECLARE @RequestFileName NVARCHAR(250);

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
            @ExistingServiceRequestFileId = [ServiceRequestFileId],
            @ExistingIsActive = [IsActive]
        FROM [dbo].[ServiceTestCases] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @TestCaseId;

        IF @TestCaseId IS NULL
        BEGIN
            RAISERROR('Service test case with Id %d not found.', 16, 1, @TestCaseId);
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

        -- Validate ServiceRequestFile if provided
        IF @ServiceRequestFileId IS NOT NULL
        BEGIN
            SELECT @RequestFileName = [Name]
            FROM [dbo].[ServiceRequestFiles]
            WHERE [Id] = @ServiceRequestFileId
              AND [IsActive] = 1;

            IF @RequestFileName IS NULL
            BEGIN
                RAISERROR('Service request file with Id %d not found or inactive.', 16, 1, @ServiceRequestFileId);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Check for duplicate name if changed
        IF @Name IS NOT NULL AND @Name <> @ExistingName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceTestCases]
                WHERE [Name] = @Name
                  AND [Id] != @TestCaseId
                  AND [IsActive] = 1
            )
            BEGIN
                RAISERROR('Test case with name "%s" already exists.', 16, 1, @Name);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[ServiceTestCases]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [ServiceRequestFileId] = @ServiceRequestFileId,
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @TestCaseId;

        -- Build notes
        SET @Notes = CONCAT('Service test case updated: ', 
                           ISNULL(@Name, @ExistingName));

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @TestCaseId AS TestCaseId,
                ISNULL(@Name, @ExistingName) AS TestCaseName,
                @ServiceRequestFileId AS ServiceRequestFileId,
                @RequestFileName AS RequestFileName,
                @IsActive AS IsActive,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestCases',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT 
            [Id] AS TestCaseId,
            [Name],
            [ServiceRequestFileId],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @RequestFileName AS RequestFileName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceTestCases]
        WHERE [Id] = @TestCaseId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service test case: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO