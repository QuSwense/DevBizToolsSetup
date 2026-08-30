/*
    Stored Procedure: usp_RemoveServiceAppPermissions
    Description: Removes specific permissions from a user on a service application.
*/
CREATE PROCEDURE [dbo].[usp_RemoveServiceAppPermissions]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @UserId NVARCHAR(20),
    @PermissionKeys NVARCHAR(MAX) = NULL,  -- NULL means remove all permissions
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
        DECLARE @ActivityId BIGINT;
        DECLARE @DeletedCount INT = 0;
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
        ORDER BY [Id] DESC;

        IF @ServiceAppId IS NULL
        BEGIN
            RAISERROR('Service application not found.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete permissions
        IF @PermissionKeys IS NULL
        BEGIN
            -- Remove all permissions for this user
            DELETE FROM [dbo].[ServiceAppPermissions]
            WHERE [ServiceApplicationId] = @ServiceAppId
              AND [UserId] = @UserId;
            
            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            -- Remove specific permissions
            DELETE sap
            FROM [dbo].[ServiceAppPermissions] sap
            INNER JOIN [dbo].[ResourcePermissions] rp ON sap.[ResourcePermissionId] = rp.[Id]
            INNER JOIN OPENJSON(@PermissionKeys) jp ON rp.[PermissionKey] = jp.[value]
            WHERE sap.[ServiceApplicationId] = @ServiceAppId
              AND sap.[UserId] = @UserId;
            
            SET @DeletedCount = @@ROWCOUNT;
        END

        -- Audit log
        SET @Notes = 'Removed ' + CAST(@DeletedCount AS NVARCHAR(10)) + ' permissions from user ' + @UserId;
        
        SET @FeatureJson = (
            SELECT 
                'PermissionRemove' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @UserId AS TargetUserId,
                @PermissionKeys AS RemovedPermissions,
                @DeletedCount AS PermissionsRemoved,
                @ResolvedUser AS PerformedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceAppPermissionRemove',
            @ActionType = 'Delete',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceApplicationPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return remaining permissions
        EXEC [dbo].[usp_GetServiceAppPermissions] @ServiceApplicationPublicId, @UserId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error removing permissions: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO