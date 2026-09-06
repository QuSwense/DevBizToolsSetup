CREATE PROCEDURE [dbo].[usp_CreateRole]
    @Name NVARCHAR(50),
    @Description NVARCHAR(500) = NULL,
    @IsSystemRole BIT = 0,
    @IsActive BIT = 1,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUser NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId BIGINT = NULL;
    DECLARE @NewPublicId UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        /* ---------- Validation ---------- */
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = N''
            RAISERROR('Role name cannot be empty.', 16, 1);

        IF EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [Name] = @Name)
            RAISERROR('A role with the name ''%s'' already exists.', 16, 1, @Name);

        /* ---------- Transaction ---------- */
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END;

        INSERT INTO [dbo].[Roles]
            ([PublicId], [Name], [Description], [IsSystemRole], [IsActive], [CreatedAt], [CreatedBy])
        VALUES
            (@NewPublicId, @Name, @Description, @IsSystemRole, @IsActive, GETDATE(), @ResolvedUser);

        /* ---------- Audit ---------- */
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'RoleCreate',
            @ActionType = 'Create',
            @RelatedEntityType = 'Roles',
            @RelatedEntityId = @NewPublicId,
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
        WHERE [PublicId] = @NewPublicId;
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
