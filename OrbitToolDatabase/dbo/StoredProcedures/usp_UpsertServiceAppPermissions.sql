/*
    Stored Procedure: usp_UpsertServiceAppPermissions
    Description: Adds or updates permissions for a user on a service application.
*/
CREATE PROCEDURE [dbo].[usp_UpsertServiceAppPermissions]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @UserId NVARCHAR(20),
    @PermissionKeys NVARCHAR(MAX),  -- JSON array of permission keys
    @IsGranted BIT = 1,
    @CreatedBy NVARCHAR(20) = NULL
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
        DECLARE @ServiceAppId INT;
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @PermissionId BIGINT;
        DECLARE @ExistingPermissionId BIGINT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @FeatureJson NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @CreatedBy,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the service application internal ID
        SELECT TOP 1 @ServiceAppId = [Id]
        FROM [dbo].[ServiceApplications]
        WHERE [PublicId] = @ServiceApplicationPublicId
          AND [IsActive] = 1
        ORDER BY [Id] DESC;

        IF @ServiceAppId IS NULL
        BEGIN
            RAISERROR('Service application not found or inactive.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verify user exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId)
        BEGIN
            RAISERROR('User %s not found.', 16, 1, @UserId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Process permissions using a cursor
        DECLARE @PermissionKey NVARCHAR(MAX);
        DECLARE permission_cursor CURSOR FOR
        SELECT value
        FROM OPENJSON(@PermissionKeys);

        OPEN permission_cursor;
        FETCH NEXT FROM permission_cursor INTO @PermissionKey;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Get the resource permission ID
            SELECT @PermissionId = [Id]
            FROM [dbo].[ResourcePermissions]
            WHERE [PermissionKey] = @PermissionKey;

            IF @PermissionId IS NULL
            BEGIN
                -- If permission doesn't exist, create it
                INSERT INTO [dbo].[ResourcePermissions] (
                    [PermissionKey],
                    [CreatedBy],
                    [CreatedAt],
                    [LastUpdatedBy],
                    [LastUpdatedAt]
                )
                VALUES (
                    @PermissionKey,
                    @ResolvedUser,
                    GETDATE(),
                    @ResolvedUser,
                    GETDATE()
                );

                SET @PermissionId = SCOPE_IDENTITY();
            END

            -- Check if permission already exists for this user and service
            SELECT @ExistingPermissionId = [Id]
            FROM [dbo].[ServiceAppPermissions]
            WHERE [ServiceApplicationId] = @ServiceAppId
              AND [UserId] = @UserId
              AND [ResourcePermissionId] = @PermissionId;

            IF @ExistingPermissionId IS NULL
            BEGIN
                -- Insert new permission
                INSERT INTO [dbo].[ServiceAppPermissions] (
                    [PublicId],
                    [ServiceApplicationId],
                    [UserId],
                    [ResourcePermissionId],
                    [IsGranted],
                    [CreatedAt],
                    [CreatedBy],
                    [LastUpdatedAt],
                    [LastUpdatedBy]
                )
                VALUES (
                    NEWID(),
                    @ServiceAppId,
                    @UserId,
                    @PermissionId,
                    @IsGranted,
                    GETDATE(),
                    @ResolvedUser,
                    GETDATE(),
                    @ResolvedUser
                );
            END
            ELSE
            BEGIN
                -- Update existing permission
                UPDATE [dbo].[ServiceAppPermissions]
                SET 
                    [IsGranted] = @IsGranted,
                    [LastUpdatedAt] = GETDATE(),
                    [LastUpdatedBy] = @ResolvedUser
                WHERE [Id] = @ExistingPermissionId;
            END

            FETCH NEXT FROM permission_cursor INTO @PermissionKey;
        END

        CLOSE permission_cursor;
        DEALLOCATE permission_cursor;

        -- Audit log
        SET @Notes = 'Permissions updated for user ' + @UserId + ' on service ' + CAST(@ServiceApplicationPublicId AS NVARCHAR(50));
        
        SET @FeatureJson = (
            SELECT 
                'PermissionUpdate' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @UserId AS TargetUserId,
                @PermissionKeys AS Permissions,
                @IsGranted AS IsGranted,
                @ResolvedUser AS PerformedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceAppPermissionUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceApplicationPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return current permissions
        EXEC [dbo].[usp_GetServiceAppPermissions] @ServiceApplicationPublicId, @UserId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating permissions: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO