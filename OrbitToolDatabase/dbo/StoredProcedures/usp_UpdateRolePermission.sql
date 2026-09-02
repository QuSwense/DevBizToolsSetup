/*
    Stored Procedure: usp_UpdateRolePermission
    Description: Updates an existing role permission with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateRolePermission]
    @RolePermissionId BIGINT,
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
        DECLARE @RoleId INT;
        DECLARE @RoleName NVARCHAR(50);
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
            @RoleId = rp.[RoleId],
            @RoleName = ro.[Name],
            @ExistingIsGranted = rp.[IsGranted],
            @ExistingIsActive = rp.[IsActive],
            @PermissionKey = res.[PermissionKey]
        FROM [dbo].[RolePermissions] rp WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [dbo].[Roles] ro ON rp.[RoleId] = ro.[Id]
        INNER JOIN [dbo].[ResourcePermissions] res ON rp.[ResourcePermissionId] = res.[Id]
        WHERE rp.[Id] = @RolePermissionId;

        IF @RolePermissionId IS NULL
        BEGIN
            RAISERROR('Role permission with Id %d not found.', 16, 1, @RolePermissionId);
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
                rp.[Id] AS RolePermissionId,
                rp.[RoleId],
                ro.[Name] AS Role,
                rp.[ResourcePermissionId],
                rp.[IsGranted],
                rp.[IsActive],
                rp.[CreatedAt],
                rp.[CreatedBy],
                rp.[LastUpdatedAt],
                rp.[LastUpdatedBy],
                @PermissionKey AS PermissionKey
            FROM [dbo].[RolePermissions] rp
            INNER JOIN [dbo].[Roles] ro ON rp.[RoleId] = ro.[Id]
            WHERE rp.[Id] = @RolePermissionId;
            
            RETURN;
        END

        -- Update the record
        UPDATE [dbo].[RolePermissions]
        SET
            [IsGranted] = ISNULL(@IsGranted, [IsGranted]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @RolePermissionId;

        -- Build notes
        SET @Notes = CONCAT('Role permission updated for role: ', @RoleName, 
                           ' with permission: ', @PermissionKey);
        IF @GrantedChanged = 1
            SET @Notes = CONCAT(@Notes, ' Granted: ', CASE WHEN @IsGranted = 1 THEN 'Yes' ELSE 'No' END);
        IF @ActiveChanged = 1
            SET @Notes = CONCAT(@Notes, ' Active: ', CASE WHEN @IsActive = 1 THEN 'Yes' ELSE 'No' END);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @RolePermissionId AS RolePermissionId,
                @RoleId AS RoleId,
                @RoleName AS Role,
                @PermissionKey AS PermissionKey,
                @IsGranted AS IsGranted,
                @IsActive AS IsActive,
                @GrantedChanged AS GrantedChanged,
                @ActiveChanged AS ActiveChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RolePermissionUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RolePermissions',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT 
            rp.[Id] AS RolePermissionId,
            rp.[RoleId],
            ro.[Name] AS Role,
            rp.[ResourcePermissionId],
            rp.[IsGranted],
            rp.[IsActive],
            rp.[CreatedAt],
            rp.[CreatedBy],
            rp.[LastUpdatedAt],
            rp.[LastUpdatedBy],
            @PermissionKey AS PermissionKey,
            @ActivityId AS AuditActivityId
        FROM [dbo].[RolePermissions] rp
        INNER JOIN [dbo].[Roles] ro ON rp.[RoleId] = ro.[Id]
        WHERE rp.[Id] = @RolePermissionId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating role permission: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO