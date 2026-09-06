-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Updates an existing resource permission (keyed on PublicId)
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateResourcePermission]
    @PublicId UNIQUEIDENTIFIER,
    @PermissionKey NVARCHAR(MAX) = NULL,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId BIGINT;
    DECLARE @ResolvedUserId NVARCHAR(20);
    DECLARE @ExistingId BIGINT;
    DECLARE @ExistingPermissionKey NVARCHAR(MAX);

    BEGIN TRY
        -- Resolve user context
        SET @ResolvedUserId = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');

        -- Start transaction if not already in one
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        -- Look up existing record with lock
        SELECT
            @ExistingId = [Id],
            @ExistingPermissionKey = [PermissionKey]
        FROM [dbo].[ResourcePermissions] WITH (UPDLOCK, HOLDLOCK)
        WHERE [PublicId] = @PublicId;

        -- Validation: Record exists
        IF @ExistingId IS NULL
        BEGIN
            RAISERROR('ResourcePermission not found for the specified PublicId.', 16, 1);
            RETURN;
        END

        -- Validation: PermissionKey unique if changed
        IF @PermissionKey IS NOT NULL AND @PermissionKey <> @ExistingPermissionKey
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = @PermissionKey AND [PublicId] <> @PublicId)
            BEGIN
                RAISERROR('PermissionKey already exists. Must be unique.', 16, 1);
                RETURN;
            END
        END

        -- Update only changed fields using ISNULL
        UPDATE [dbo].[ResourcePermissions]
        SET
            [PermissionKey] = ISNULL(@PermissionKey, [PermissionKey]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUserId
        WHERE [PublicId] = @PublicId;

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUserId,
            @ActivityType = 'ResourcePermissionUpdate',
            @ActionType = 'Update',
            @RelatedEntityType = 'ResourcePermissions',
            @RelatedEntityId = @PublicId,
            @ActivityId = @ActivityId OUTPUT;

        -- Commit if we started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return result set
        SELECT
            [Id],
            [PublicId],
            [PermissionKey],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ResourcePermissions]
        WHERE [PublicId] = @PublicId;

    END TRY
    BEGIN CATCH
        -- Rollback if we started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw error
        THROW;
    END CATCH
END
