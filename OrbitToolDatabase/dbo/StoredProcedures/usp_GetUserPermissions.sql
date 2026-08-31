/*
    Stored Procedure: usp_GetUserPermissions
    Description: Gets all permissions for a specific user.
*/
CREATE PROCEDURE [dbo].[usp_GetUserPermissions]
    @UserId NVARCHAR(20) = NULL,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        up.[Id] AS UserPermissionId,
        up.[PublicId],
        up.[UserId],
        up.[ResourcePermissionId],
        up.[IsGranted],
        up.[IsActive],
        up.[CreatedAt],
        up.[CreatedBy],
        up.[LastUpdatedAt],
        up.[LastUpdatedBy],
        rp.[PermissionKey],
        CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName,
        u.[Email] AS UserEmail,
        CASE 
            WHEN up.[IsGranted] = 1 THEN 'Granted'
            ELSE 'Denied'
        END AS PermissionStatus,
        CASE 
            WHEN up.[IsActive] = 1 THEN 'Active'
            ELSE 'Inactive'
        END AS StatusDescription
    FROM [dbo].[UserPermissions] up
    INNER JOIN [dbo].[ResourcePermissions] rp ON up.[ResourcePermissionId] = rp.[Id]
    INNER JOIN [dbo].[Users] u ON up.[UserId] = u.[UserId]
    WHERE (@UserId IS NULL OR up.[UserId] = @UserId)
      AND (@IncludeInactive = 1 OR up.[IsActive] = 1)
    ORDER BY up.[UserId], rp.[PermissionKey];
END;
GO