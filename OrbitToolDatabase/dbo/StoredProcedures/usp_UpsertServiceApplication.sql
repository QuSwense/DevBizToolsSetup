/*
    Stored Procedure: usp_UpsertServiceApplication
    Description: Inserts or updates a service application using PublicId and RecordVersion for concurrency.
    Includes comprehensive audit logging for all changes.
    
    Versioning Logic:
    - If Name, Description, ServiceType, or ServiceAppAuthenticationId changes: In-place update
    - If BaseUrl, DefinitionType, DefinitionRelativeUrl, or HealthcheckRelativeUrl changes: New version created
    - If IsActive changes: In-place update
*/
CREATE PROCEDURE [dbo].[usp_UpsertServiceApplication]
    @PublicId UNIQUEIDENTIFIER,
    @RecordVersion VARCHAR(50),  -- For optimistic concurrency check
    @ServiceType VARCHAR(10) = NULL,
    @ServiceAppAuthenticationId UNIQUEIDENTIFIER = NULL,  -- PublicId of auth config
    @Name NVARCHAR(200) = NULL,
    @BaseUrl NVARCHAR(500) = NULL,
    @DefinitionType VARCHAR(20) = NULL,
    @DefinitionRelativeUrl NVARCHAR(250) = NULL,
    @HealthcheckRelativeUrl NVARCHAR(250) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @IsActive BIT = NULL,  -- Optional: toggle active status
    @ActivityNotes NVARCHAR(MAX) = NULL  -- Optional: notes for audit log
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Manage nested transactions gracefully (.NET compatibility)
    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        -- 2. Declare variables
        DECLARE @ExistingId INT;
        DECLARE @ExistingPublicId UNIQUEIDENTIFIER;
        DECLARE @ExistingName NVARCHAR(200);
        DECLARE @ExistingServiceType VARCHAR(10);
        DECLARE @ExistingBaseUrl NVARCHAR(500);
        DECLARE @ExistingDefinitionType VARCHAR(20);
        DECLARE @ExistingDefinitionRelativeUrl NVARCHAR(250);
        DECLARE @ExistingHealthcheckRelativeUrl NVARCHAR(250);
        DECLARE @ExistingDescription NVARCHAR(MAX);
        DECLARE @ExistingIsActive BIT;
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingAuthId INT;
        DECLARE @ExistingCreatedAt DATETIME;
        DECLARE @ExistingCreatedBy NVARCHAR(20);
        DECLARE @ExistingLastUpdatedBy NVARCHAR(20);
        DECLARE @NewAuthId INT = NULL;
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NameChanged BIT = 0;
        DECLARE @DescriptionChanged BIT = 0;
        DECLARE @ServiceTypeChanged BIT = 0;
        DECLARE @AuthChanged BIT = 0;
        DECLARE @IsActiveChanged BIT = 0;
        DECLARE @UrlChanged BIT = 0;
        DECLARE @OldValueJson NVARCHAR(MAX);
        DECLARE @NewValueJson NVARCHAR(MAX);
        DECLARE @ChangeType NVARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @LogMessage NVARCHAR(MAX);

        -- 3. Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- 4. Get the internal auth ID from PublicId
        IF @ServiceAppAuthenticationId IS NOT NULL
        BEGIN
            SELECT @NewAuthId = [Id]
            FROM [dbo].[ServiceAppAuthentications]
            WHERE [PublicId] = @ServiceAppAuthenticationId
              AND [IsActive] = 1;
            
            IF @NewAuthId IS NULL
            BEGIN
                RAISERROR('Invalid authentication configuration. Please select an active authentication.', 16, 1);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- 5. Get the current record with locking
        SELECT TOP 1
            @ExistingId = [Id],
            @ExistingPublicId = [PublicId],
            @ExistingName = [Name],
            @ExistingServiceType = [ServiceType],
            @ExistingBaseUrl = [BaseUrl],
            @ExistingDefinitionType = [DefinitionType],
            @ExistingDefinitionRelativeUrl = [DefinitionRelativeUrl],
            @ExistingHealthcheckRelativeUrl = [HealthcheckRelativeUrl],
            @ExistingDescription = [Description],
            @ExistingIsActive = [IsActive],
            @ExistingRecordVersion = [RecordVersion],
            @ExistingAuthId = [ServiceAppAuthenticationId],
            @ExistingCreatedAt = [CreatedAt],
            @ExistingCreatedBy = [CreatedBy],
            @ExistingLastUpdatedBy = [LastUpdatedBy]
        FROM [dbo].[ServiceApplications] WITH (UPDLOCK, HOLDLOCK)
        WHERE [PublicId] = @PublicId
        ORDER BY [Id] DESC;

        -- 6. Validate record exists
        DECLARE @PublicIdText VARCHAR(36) = CONVERT(varchar(36), @PublicId);
        IF @ExistingId IS NULL
        BEGIN
            RAISERROR('Service application with PublicId %s not found.', 16, 1, @PublicIdText);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 7. Concurrency check - ensure record hasn't been modified
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 8. Build old values JSON for audit
        SET @OldValueJson = (
            SELECT 
                @ExistingName AS Name,
                @ExistingServiceType AS ServiceType,
                @ExistingBaseUrl AS BaseUrl,
                @ExistingDefinitionType AS DefinitionType,
                @ExistingDefinitionRelativeUrl AS DefinitionRelativeUrl,
                @ExistingHealthcheckRelativeUrl AS HealthcheckRelativeUrl,
                @ExistingDescription AS Description,
                @ExistingIsActive AS IsActive,
                @ExistingRecordVersion AS RecordVersion,
                (SELECT [PublicId] FROM [dbo].[ServiceAppAuthentications] WHERE [Id] = @ExistingAuthId) AS AuthenticationId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- 9. Check for duplicate Name (if Name is being updated)
        IF @Name IS NOT NULL AND @Name <> @ExistingName
        BEGIN
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceApplications] 
                WHERE [Name] = @Name 
                  AND [PublicId] != @PublicId
                  AND [IsActive] = 1
            )
            BEGIN
                RAISERROR('An active service application with the name "%s" already exists.', 16, 1, @Name);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
            SET @NameChanged = 1;
        END

        -- 10. Determine what changed
        IF @Description IS NOT NULL AND @Description <> @ExistingDescription
            SET @DescriptionChanged = 1;

        IF @ServiceType IS NOT NULL AND @ServiceType <> @ExistingServiceType
            SET @ServiceTypeChanged = 1;

        IF @NewAuthId != @ExistingAuthId OR (@NewAuthId IS NULL AND @ExistingAuthId IS NOT NULL) OR (@NewAuthId IS NOT NULL AND @ExistingAuthId IS NULL)
            SET @AuthChanged = 1;

        IF @IsActive IS NOT NULL AND @IsActive <> @ExistingIsActive
            SET @IsActiveChanged = 1;

        -- Check if URL-related fields changed (these trigger new version)
        IF (@BaseUrl IS NOT NULL AND @BaseUrl <> @ExistingBaseUrl)
           OR (@DefinitionType IS NOT NULL AND @DefinitionType <> @ExistingDefinitionType)
           OR (@DefinitionRelativeUrl IS NOT NULL AND @DefinitionRelativeUrl <> @ExistingDefinitionRelativeUrl)
           OR (@HealthcheckRelativeUrl IS NOT NULL AND @HealthcheckRelativeUrl <> @ExistingHealthcheckRelativeUrl)
        BEGIN
            SET @UrlChanged = 1;
        END

        -- 11. Determine the change type for audit
        IF @UrlChanged = 1
        BEGIN
            SET @ChangeType = 'VersionUpdate';  -- New version created due to URL changes
        END
        ELSE IF @IsActiveChanged = 1
        BEGIN
            SET @ChangeType = 'StatusToggle';  -- Active status toggled
        END
        ELSE IF @NameChanged = 1 OR @DescriptionChanged = 1 OR @ServiceTypeChanged = 1 OR @AuthChanged = 1
        BEGIN
            SET @ChangeType = 'InPlaceUpdate';  -- Non-URL fields updated
        END
        ELSE
        BEGIN
            -- No changes detected
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;
            
            -- Return existing record
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
                [LastUpdatedBy]
            FROM [dbo].[ServiceApplications]
            WHERE [Id] = @ExistingId;
            
            RETURN;
        END

        -- 12. Determine if we need a new version or in-place update
        IF @UrlChanged = 1
        BEGIN
            -- CASE: URL Changed - Create new version
            -- First deactivate the old record
            UPDATE [dbo].[ServiceApplications]
            SET 
                [IsActive] = 0,
                [LastUpdatedAt] = GETDATE(),
                [LastUpdatedBy] = @ResolvedUser
            WHERE [Id] = @ExistingId;

            -- Calculate new version
            SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

            -- Insert new version with same PublicId
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
                @ExistingPublicId,
                ISNULL(@ServiceType, @ExistingServiceType),
                @NewAuthId,
                ISNULL(@Name, @ExistingName),
                ISNULL(@BaseUrl, @ExistingBaseUrl),
                ISNULL(@DefinitionType, @ExistingDefinitionType),
                ISNULL(@DefinitionRelativeUrl, @ExistingDefinitionRelativeUrl),
                ISNULL(@HealthcheckRelativeUrl, @ExistingHealthcheckRelativeUrl),
                ISNULL(@Description, @ExistingDescription),
                ISNULL(@IsActive, 1),  -- New version starts as active by default
                @NewRecordVersion,
                GETDATE(),
                @ResolvedUser,
                GETDATE(),
                @ResolvedUser
            );

            -- Get the newly inserted ID
            SET @ExistingId = SCOPE_IDENTITY();
            
            -- Build new values JSON for audit
            SET @NewValueJson = (
                SELECT 
                    ISNULL(@Name, @ExistingName) AS Name,
                    ISNULL(@ServiceType, @ExistingServiceType) AS ServiceType,
                    ISNULL(@BaseUrl, @ExistingBaseUrl) AS BaseUrl,
                    ISNULL(@DefinitionType, @ExistingDefinitionType) AS DefinitionType,
                    ISNULL(@DefinitionRelativeUrl, @ExistingDefinitionRelativeUrl) AS DefinitionRelativeUrl,
                    ISNULL(@HealthcheckRelativeUrl, @ExistingHealthcheckRelativeUrl) AS HealthcheckRelativeUrl,
                    ISNULL(@Description, @ExistingDescription) AS Description,
                    ISNULL(@IsActive, 1) AS IsActive,
                    @NewRecordVersion AS NewRecordVersion,
                    @ExistingRecordVersion AS OldRecordVersion,
                    (SELECT [PublicId] FROM [dbo].[ServiceAppAuthentications] WHERE [Id] = @NewAuthId) AS AuthenticationId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            );

            -- Prepare audit log message
            SET @LogMessage = 'New version created. Old version: ' + @ExistingRecordVersion + ', New version: ' + @NewRecordVersion;
            IF @BaseUrl IS NOT NULL AND @BaseUrl <> @ExistingBaseUrl
                SET @LogMessage = @LogMessage + '. BaseUrl changed from ' + @ExistingBaseUrl + ' to ' + @BaseUrl;
            IF @DefinitionRelativeUrl IS NOT NULL AND @DefinitionRelativeUrl <> @ExistingDefinitionRelativeUrl
                SET @LogMessage = @LogMessage + '. Definition URL changed.';
            IF @HealthcheckRelativeUrl IS NOT NULL AND @HealthcheckRelativeUrl <> @ExistingHealthcheckRelativeUrl
                SET @LogMessage = @LogMessage + '. Healthcheck URL changed.';
        END
        ELSE
        BEGIN
            -- CASE: In-place Update (No URL changes)
            -- Calculate new version for in-place update
            SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

            UPDATE [dbo].[ServiceApplications]
            SET 
                [ServiceType] = ISNULL(@ServiceType, [ServiceType]),
                [ServiceAppAuthenticationId] = @NewAuthId,
                [Name] = ISNULL(@Name, [Name]),
                [Description] = ISNULL(@Description, [Description]),
                [IsActive] = ISNULL(@IsActive, [IsActive]),
                [RecordVersion] = @NewRecordVersion,
                [LastUpdatedAt] = GETDATE(),
                [LastUpdatedBy] = @ResolvedUser
            WHERE [Id] = @ExistingId;

            -- Build new values JSON for audit
            SET @NewValueJson = (
                SELECT 
                    ISNULL(@Name, @ExistingName) AS Name,
                    ISNULL(@ServiceType, @ExistingServiceType) AS ServiceType,
                    @ExistingBaseUrl AS BaseUrl,  -- Unchanged
                    @ExistingDefinitionType AS DefinitionType,  -- Unchanged
                    @ExistingDefinitionRelativeUrl AS DefinitionRelativeUrl,  -- Unchanged
                    @ExistingHealthcheckRelativeUrl AS HealthcheckRelativeUrl,  -- Unchanged
                    ISNULL(@Description, @ExistingDescription) AS Description,
                    ISNULL(@IsActive, @ExistingIsActive) AS IsActive,
                    @NewRecordVersion AS NewRecordVersion,
                    @ExistingRecordVersion AS OldRecordVersion,
                    (SELECT [PublicId] FROM [dbo].[ServiceAppAuthentications] WHERE [Id] = @NewAuthId) AS AuthenticationId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            );

            -- Prepare audit log message
            SET @LogMessage = 'Record updated. New version: ' + @NewRecordVersion;
            IF @NameChanged = 1
                SET @LogMessage = @LogMessage + '. Name changed from ' + @ExistingName + ' to ' + ISNULL(@Name, @ExistingName);
            IF @DescriptionChanged = 1
                SET @LogMessage = @LogMessage + '. Description updated.';
            IF @ServiceTypeChanged = 1
                SET @LogMessage = @LogMessage + '. ServiceType changed from ' + @ExistingServiceType + ' to ' + ISNULL(@ServiceType, @ExistingServiceType);
            IF @AuthChanged = 1
                SET @LogMessage = @LogMessage + '. Authentication changed.';
            IF @IsActiveChanged = 1
                SET @LogMessage = @LogMessage + '. Status changed from ' + CASE WHEN @ExistingIsActive = 1 THEN 'Active' ELSE 'Inactive' END + ' to ' + CASE WHEN ISNULL(@IsActive, @ExistingIsActive) = 1 THEN 'Active' ELSE 'Inactive' END;
        END

        -- 13. Insert audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                @ChangeType AS ChangeType,
                @PublicId AS ServiceId,
                ISNULL(@Name, @ExistingName) AS ServiceName,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @LogMessage AS Message,
                @OldValueJson AS OldValues,
                @NewValueJson AS NewValues,
                @ActivityNotes AS Notes
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceApplicationUpdate',
            @ActionType = @ChangeType,
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @PublicId,
            @Notes = @LogMessage,
            @ActivityId = @ActivityId OUTPUT;

        -- 14. Return the updated record
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
            @ActivityId AS AuditActivityId  -- Return the activity ID for reference
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @ExistingId;

        -- 15. Commit if this SP started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Rollback only if this SP opened the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service application: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO