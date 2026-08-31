/*
    Stored Procedure: usp_CreateServiceTestCase
    Description: Creates a new service test case with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateServiceTestCase]
    @Name NVARCHAR(200),
    @ServiceRequestFileId INT = NULL,
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
        DECLARE @RequestFileName NVARCHAR(250);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

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

        -- Check for duplicate name
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceTestCases]
            WHERE [Name] = @Name
              AND [IsActive] = 1
        )
        BEGIN
            RAISERROR('Test case with name "%s" already exists.', 16, 1, @Name);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[ServiceTestCases] (
            [Name],
            [ServiceRequestFileId],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @Name,
            @ServiceRequestFileId,
            1,  -- Active by default
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Service test case created: ', @Name, 
                           CASE WHEN @ServiceRequestFileId IS NOT NULL 
                                THEN CONCAT(' (Request File: ', @RequestFileName, ')') 
                                ELSE '' END);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @Name AS TestCaseName,
                @ServiceRequestFileId AS ServiceRequestFileId,
                @RequestFileName AS RequestFileName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceTestCaseCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceTestCases',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
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
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating service test case: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO