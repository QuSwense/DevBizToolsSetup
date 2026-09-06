CREATE PROCEDURE [dbo].[usp_UpdateRole]
    @PublicId UNIQUEIDENTIFIER,
    @Name NVARCHAR(50) = NULL,
    @Description NVARCHAR(500) = NULL,
    @IsActive BIT = NULL,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUser NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId BIGINT = NULL;

    DECLARE @CurrentName NVARCHAR(50);
    DECLARE @CurrentDescription NVARCHAR(500);
    DECLARE @IsSystemRole BIT;

    BEGIN TRY
        /* ---------- Transaction (update locks must be held inside) ---------- */
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END;

        SELECT
            @CurrentName = [Name],
            @CurrentDescription = [Description],
            @IsSystemRole = [IsSystemRole]
        FROM [dbo].[Roles] WITH (UPDLOCK, HOLDLOCK)
        WHERE [PublicId] = @PublicId;

        /* ---------- Validation ---------- */
        IF @CurrentName IS NULL
            RAISERROR('Role with the specified PublicId does not exist.', 16, 1);

        IF @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) = N''
            RAISERROR('Role name cannot be empty.', 16, 1);

        IF @Name IS NOT NULL
           AND @Name <> @CurrentName
           AND EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [Name] = @Name AND [PublicId] <> @PublicId)
            RAISERROR('A role with the name ''%s'' already exists.', 16, 1, @Name);

        /* System roles: only the IsActive flag may be changed */
        IF @IsSystemRole = 1
           AND (
                   (@Name IS NOT NULL AND @Name <> @CurrentName)
                OR (@Description IS NOT NULL AND ISNULL(@Description, N'') <> ISNULL(@CurrentDescription, N''))
               )
            RAISERROR('System roles cannot be modified; only the IsActive flag may be changed.', 16, 1);

        /* ---------- Update (only supplied fields) ---------- */
        UPDATE [dbo].[Roles]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [Description] = ISNULL(@Description, [Description]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [PublicId] = @PublicId;

        /* ---------- Audit ---------- */
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RoleUpdate',
            @ActionType = 'Update',
            @RelatedEntityType = 'Roles',
            @RelatedEntityId = @PublicId,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1
            COMMIT TRANSACTION;

        /* ---------- Result ---------- */
        SELECT
            [Id],
            [PublicId],
            [Name],
            [Description],
            [IsSystemRole],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS [AuditActivityId]
        FROM [dbo].[Roles]
        WHERE [PublicId] = @PublicId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
