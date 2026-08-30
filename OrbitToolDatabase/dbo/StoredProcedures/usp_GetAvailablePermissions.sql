/*
    Stored Procedure: usp_GetAvailablePermissions
    Description: Gets all available resource permissions in the system.
*/
CREATE PROCEDURE [dbo].[usp_GetAvailablePermissions]
    @SearchTerm NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [Id] AS ResourcePermissionId,
        [PublicId],
        [PermissionKey],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy],
        -- Count of users with this permission
        (
            SELECT COUNT(DISTINCT [UserId])
            FROM [dbo].[ServiceAppPermissions] sap
            WHERE sap.[ResourcePermissionId] = rp.[Id]
              AND sap.[IsGranted] = 1
        ) AS UserCount,
        -- Count of services using this permission
        (
            SELECT COUNT(DISTINCT [ServiceApplicationId])
            FROM [dbo].[ServiceAppPermissions] sap
            WHERE sap.[ResourcePermissionId] = rp.[Id]
              AND sap.[IsGranted] = 1
        ) AS ServiceCount
    FROM [dbo].[ResourcePermissions] rp
    WHERE @SearchTerm IS NULL 
       OR rp.[PermissionKey] LIKE '%' + @SearchTerm + '%'
    ORDER BY rp.[PermissionKey];
END;
GO