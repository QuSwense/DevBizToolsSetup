CREATE PROCEDURE [dbo].[usp_GetRoles]
    @IncludeInactive BIT = 0,
    @IncludeSystemRoles BIT = 1,
    @Name NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.[Id],
        r.[PublicId],
        r.[Name],
        r.[Description],
        r.[IsSystemRole],
        r.[IsActive],
        r.[CreatedAt],
        r.[CreatedBy],
        r.[LastUpdatedAt],
        r.[LastUpdatedBy],
        (SELECT COUNT(1) FROM [dbo].[Users] u WHERE u.[RoleId] = r.[Id]) AS [UserCount],
        (SELECT COUNT(1) FROM [dbo].[RolePermissions] rp WHERE rp.[RoleId] = r.[Id]) AS [PermissionCount]
    FROM [dbo].[Roles] r
    WHERE
        (@IncludeInactive = 1 OR r.[IsActive] = 1)
        AND (@IncludeSystemRoles = 1 OR r.[IsSystemRole] = 0)
        AND (@Name IS NULL OR r.[Name] = @Name)
    ORDER BY r.[Name] ASC;
END;
GO
