/*
    Stored Procedure: usp_CreateRolePermission
    Description: Creates a new role permission with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateRolePermission]
    @Role NVARCHAR(50),
    @ResourcePermissionId BIGINT,
    @IsGranted BIT = 1,
    @IsActive BIT = 1,
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
        DECLARE @NewId BIGINT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @PermissionKey NVARCHAR(MAX);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate ResourcePermission exists
        SELECT @PermissionKey = [PermissionKey]
        FROM [dbo].[ResourcePermissions]
        WHERE [Id] = @ResourcePermissionId;

        IF @PermissionKey IS NULL
        BEGIN
            RAISERROR('Resource permission with Id %d not found.', 16, 1, @ResourcePermissionId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate role permission
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[RolePermissions]
            WHERE [Role] = @Role
              AND [ResourcePermissionId] = @ResourcePermissionId
              AND [IsActive] = 1
        )
        BEGIN
            RAISERROR('Permission "%s" already exists for role "%s".', 16, 1, @PermissionKey, @Role);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new record
        INSERT INTO [dbo].[RolePermissions] (
            [Role],
            [ResourcePermissionId],
            [IsGranted],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @Role,
            @ResourcePermissionId,
            @IsGranted,
            @IsActive,
            GETDATE(),
            @ResolvedUser,
            NULL,
            NULL
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Role permission created for role: ', @Role, 
                           ' with permission: ', @PermissionKey, 
                           ' (Granted: ', CASE WHEN @IsGranted = 1 THEN 'Yes' ELSE 'No' END, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @Role AS Role,
                @ResourcePermissionId AS ResourcePermissionId,
                @PermissionKey AS PermissionKey,
                @IsGranted AS IsGranted,
                @IsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RolePermissionCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'RolePermissions',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id] AS RolePermissionId,
            [Role],
            [ResourcePermissionId],
            [IsGranted],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @PermissionKey AS PermissionKey,
            @ActivityId AS AuditActivityId
        FROM [dbo].[RolePermissions]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating role permission: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO