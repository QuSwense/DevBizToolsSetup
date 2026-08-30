/*
    Stored Procedure: usp_CreateServiceApplication
    Description: Creates a new service application with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateServiceApplication]
    @ServiceType VARCHAR(10),
    @ServiceAppAuthenticationId UNIQUEIDENTIFIER = NULL,
    @Name NVARCHAR(200),
    @BaseUrl NVARCHAR(500),
    @DefinitionType VARCHAR(20) = NULL,
    @DefinitionRelativeUrl NVARCHAR(250) = NULL,
    @HealthcheckRelativeUrl NVARCHAR(250) = NULL,
    @Description NVARCHAR(MAX) = NULL,
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
        DECLARE @AuthId INT = NULL;
        DECLARE @NewPublicId UNIQUEIDENTIFIER = NEWID();
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get auth internal ID from PublicId
        IF @ServiceAppAuthenticationId IS NOT NULL
        BEGIN
            SELECT @AuthId = [Id]
            FROM [dbo].[ServiceAppAuthentications]
            WHERE [PublicId] = @ServiceAppAuthenticationId
              AND [IsActive] = 1;
            
            IF @AuthId IS NULL
            BEGIN
                RAISERROR('Invalid authentication configuration. Please select an active authentication.', 16, 1);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Check for duplicate name
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceApplications] 
            WHERE [Name] = @Name 
              AND [IsActive] = 1
        )
        BEGIN
            RAISERROR('An active service application with the name "%s" already exists.', 16, 1, @Name);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate initial version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[ServiceApplications] (
            [PublicId],
            [ServiceType],
            [ServiceAppAuthenticationId],
            [Name],
            [BaseUrl],
            [DefinitionType],
            [DefinitionRelativeUrl],
            [HealthcheckRelativeUrl],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @NewPublicId,
            @ServiceType,
            @AuthId,
            @Name,
            @BaseUrl,
            @DefinitionType,
            @DefinitionRelativeUrl,
            @HealthcheckRelativeUrl,
            @Description,
            1,  -- New records are active by default
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,  -- No updates yet
            NULL   -- No updates yet
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes string
        SET @Notes = 'New service application created: ' + @Name;

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @NewPublicId AS ServiceId,
                @Name AS ServiceName,
                @ServiceType AS ServiceType,
                @BaseUrl AS BaseUrl,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceApplicationCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @NewPublicId,
            @Notes = @Notes,  -- Use the variable
            @ActivityId = @ActivityId OUTPUT;

        -- Return the new record
        SELECT 
            [PublicId],
            [Id] AS InternalId,
            [ServiceType],
            [ServiceAppAuthenticationId] AS AuthInternalId,
            (SELECT [PublicId] FROM [dbo].[ServiceAppAuthentications] WHERE [Id] = [ServiceAppAuthenticationId]) AS AuthenticationId,
            [Name],
            [BaseUrl],
            [DefinitionType],
            [DefinitionRelativeUrl],
            [HealthcheckRelativeUrl],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @NewId;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating service application: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO