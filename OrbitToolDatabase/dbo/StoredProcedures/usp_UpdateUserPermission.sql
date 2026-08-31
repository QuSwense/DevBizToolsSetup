/*
    Stored Procedure: usp_UpdateUserPermission
    Description: Updates an existing user permission with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateUserPermission]
    @UserPermissionId BIGINT,
    @IsGranted BIT = NULL,
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
        DECLARE @TargetUserId NVARCHAR(20);
        DECLARE @UserName NVARCHAR(200);
        DECLARE @PermissionKey NVARCHAR(MAX);
        DECLARE @ExistingIsGranted BIT;
        DECLARE @ExistingIsActive BIT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @TargetUserId = up.[UserId],
            @ExistingIsGranted = up.[IsGranted],
            @ExistingIsActive = up.[IsActive],
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

        -- Determine what changed
        DECLARE @GrantedChanged BIT = 0;
        DECLARE @ActiveChanged BIT = 0;

        IF @IsGranted IS NOT NULL AND @IsGranted <> @ExistingIsGranted
            SET @GrantedChanged = 1;

        IF @IsActive IS NOT NULL AND @IsActive <> @ExistingIsActive
            SET @ActiveChanged = 1;

        -- If nothing changed, return existing
        IF @GrantedChanged = 0 AND @ActiveChanged = 0
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT 
                [Id] AS UserPermissionId,
                [PublicId],
                [UserId],
                [ResourcePermissionId],
                [IsGranted],
                [IsActive],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy],
                @PermissionKey AS PermissionKey,
                @UserName AS UserFullName
            FROM [dbo].[UserPermissions]
            WHERE [Id] = @UserPermissionId;
            
            RETURN;
        END

        -- Update the record
        UPDATE [dbo].[UserPermissions]
        SET
            [IsGranted] = ISNULL(@IsGranted, [IsGranted]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @UserPermissionId;

        -- Build notes
        SET @Notes = CONCAT('User permission updated for user: ', @TargetUserId, 
                           ' (', @UserName, ') with permission: ', @PermissionKey);
        IF @GrantedChanged = 1
            SET @Notes = CONCAT(@Notes, ' Granted: ', CASE WHEN @IsGranted = 1 THEN 'Yes' ELSE 'No' END);
        IF @ActiveChanged = 1
            SET @Notes = CONCAT(@Notes, ' Active: ', CASE WHEN @IsActive = 1 THEN 'Yes' ELSE 'No' END);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @UserPermissionId AS UserPermissionId,
                @TargetUserId AS UserId,
                @UserName AS UserName,
                @PermissionKey AS PermissionKey,
                @IsGranted AS IsGranted,
                @IsActive AS IsActive,
                @GrantedChanged AS GrantedChanged,
                @ActiveChanged AS ActiveChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'UserPermissionUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'UserPermissions',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT 
            [Id] AS UserPermissionId,
            [PublicId],
            [UserId],
            [ResourcePermissionId],
            [IsGranted],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @PermissionKey AS PermissionKey,
            @UserName AS UserFullName,
            @ActivityId AS AuditActivityId
        FROM [dbo].[UserPermissions]
        WHERE [Id] = @UserPermissionId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating user permission: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO