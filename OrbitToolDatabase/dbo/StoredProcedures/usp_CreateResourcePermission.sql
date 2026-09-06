-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Creates a new resource permission
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateResourcePermission]
    @PermissionKey NVARCHAR(MAX),
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId BIGINT;
    DECLARE @NewPublicId UNIQUEIDENTIFIER;
    DECLARE @ResolvedUserId NVARCHAR(20);

    BEGIN TRY
        -- Resolve user context
        SET @ResolvedUserId = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');

        -- Validation: PermissionKey not empty
        IF @PermissionKey IS NULL OR LTRIM(RTRIM(@PermissionKey)) = ''
        BEGIN
            RAISERROR('PermissionKey cannot be empty.', 16, 1);
            RETURN;
        END

        -- Validation: PermissionKey unique
        IF EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = @PermissionKey)
        BEGIN
            RAISERROR('PermissionKey already exists. Must be unique.', 16, 1);
            RETURN;
        END

        -- Start transaction if not already in one
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        -- Generate new PublicId
        SET @NewPublicId = NEWID();

        -- Insert the resource permission
        INSERT INTO [dbo].[ResourcePermissions] (
            [PublicId],
            [PermissionKey],
            [CreatedBy]
        )
        VALUES (
            @NewPublicId,
            @PermissionKey,
            @ResolvedUserId
        );

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUserId,
            @ActivityType = 'ResourcePermissionCreate',
            @ActionType = 'Create',
            @RelatedEntityType = 'ResourcePermissions',
            @RelatedEntityId = @NewPublicId,
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
        WHERE [PublicId] = @NewPublicId;

    END TRY
    BEGIN CATCH
        -- Rollback if we started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw error
        THROW;
    END CATCH
END
