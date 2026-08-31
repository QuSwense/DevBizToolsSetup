/*
    Stored Procedure: usp_DeleteUserPermission
    Description: Soft deletes a user permission by setting IsActive = 0.
*/
CREATE PROCEDURE [dbo].[usp_DeleteUserPermission]
    @UserPermissionId BIGINT,
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
        DECLARE @TargetUserId NVARCHAR(20);
        DECLARE @UserName NVARCHAR(200);
        DECLARE @PermissionKey NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details
        SELECT TOP 1
            @TargetUserId = up.[UserId],
            @PermissionKey = res.[PermissionKey],
            @UserName = CONCAT(u.[FirstName], ' ', u.[LastName])
        FROM [dbo].[UserPermissions] up WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [dbo].[ResourcePermissions] res ON up.[ResourcePermissionId] = res.[Id]
        INNER JOIN [dbo].[Users] u ON up.[UserId] = u.[UserId]
        WHERE up.[Id] = @UserPermissionId;

        IF @UserPermissionId IS NULL
        BEGIN
            RAISERROR('User permission with Id %d not found.', 16, 1, @UserPermissionId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Soft delete
        UPDATE [dbo].[UserPermissions]
        SET
            [IsActive] = 0,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @UserPermissionId;

        -- Build notes
        SET @Notes = CONCAT('User permission deleted for user: ', @TargetUserId, 
                           ' (', @UserName, ') with permission: ', @PermissionKey);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Delete' AS ChangeType,
                @UserPermissionId AS UserPermissionId,
                @TargetUserId AS UserId,
                @UserName AS UserName,
                @PermissionKey AS PermissionKey
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'UserPermissionDelete',
            @ActionType = 'Delete',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'UserPermissions',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT 
            @UserPermissionId AS UserPermissionId,
            'User permission deleted successfully' AS Message,
            @ActivityId AS AuditActivityId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error deleting user permission: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO