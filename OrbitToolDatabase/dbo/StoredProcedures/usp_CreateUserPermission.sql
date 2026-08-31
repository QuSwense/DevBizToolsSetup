/*
    Stored Procedure: usp_CreateUserPermission
    Description: Creates a new user permission with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_CreateUserPermission]
    @UserId NVARCHAR(20),
    @ResourcePermissionId BIGINT,
    @IsGranted BIT = 1,
    @IsActive BIT = 1,
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
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NewId BIGINT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @PermissionKey NVARCHAR(MAX);
        DECLARE @UserName NVARCHAR(200);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @CreatedBy,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate User exists
        SELECT @UserName = CONCAT([FirstName], ' ', [LastName])
        FROM [dbo].[Users]
        WHERE [UserId] = @UserId;

        IF @UserName IS NULL
        BEGIN
            RAISERROR('User "%s" not found.', 16, 1, @UserId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

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

        -- Check for duplicate user permission
        IF EXISTS (
            SELECT 1 
            FROM [dbo].[UserPermissions]
            WHERE [UserId] = @UserId
              AND [ResourcePermissionId] = @ResourcePermissionId
              AND [IsActive] = 1
        )
        BEGIN
            RAISERROR('Permission "%s" already exists for user "%s".', 16, 1, @PermissionKey, @UserId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert new record
        INSERT INTO [dbo].[UserPermissions] (
            [PublicId],
            [UserId],
            [ResourcePermissionId],
            [IsGranted],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            NEWID(),
            @UserId,
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
        SET @Notes = CONCAT('User permission created for user: ', @UserId, 
                           ' (', @UserName, ') with permission: ', @PermissionKey, 
                           ' (Granted: ', CASE WHEN @IsGranted = 1 THEN 'Yes' ELSE 'No' END, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @UserId AS UserId,
                @UserName AS UserName,
                @ResourcePermissionId AS ResourcePermissionId,
                @PermissionKey AS PermissionKey,
                @IsGranted AS IsGranted,
                @IsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'UserPermissionCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'UserPermissions',
            @RelatedEntityId = NULL,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
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
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating user permission: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO