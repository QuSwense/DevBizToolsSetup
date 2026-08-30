/*
    Stored Procedure: usp_GetServiceAppPermissions
    Description: Gets all permissions for a specific user on a service application.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceAppPermissions]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @UserId NVARCHAR(20) = NULL  -- If NULL, get all users' permissions
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ServiceAppId INT;

    -- Get the service application internal ID
    SELECT TOP 1 @ServiceAppId = [Id]
    FROM [dbo].[ServiceApplications]
    WHERE [PublicId] = @ServiceApplicationPublicId
    ORDER BY [Id] DESC;

    IF @ServiceAppId IS NULL
    BEGIN
        RAISERROR('Service application not found.', 16, 1);
        RETURN;
    END

    SELECT 
        sap.[Id] AS PermissionId,
        sap.[PublicId] AS PermissionPublicId,
        sap.[UserId],
        u.[FullName] AS UserFullName,
        u.[Email] AS UserEmail,
        sap.[IsGranted],
        rp.[PermissionKey],
        rp.[Id] AS ResourcePermissionId,
        sap.[CreatedAt] AS PermissionCreatedAt,
        sap.[CreatedBy] AS PermissionCreatedBy,
        sap.[LastUpdatedAt] AS PermissionLastUpdatedAt,
        sap.[LastUpdatedBy] AS PermissionLastUpdatedBy,
        -- Service details
        sa.[PublicId] AS ServicePublicId,
        sa.[Name] AS ServiceName,
        sa.[RecordVersion] AS ServiceVersion
    FROM [dbo].[ServiceAppPermissions] sap
    INNER JOIN [dbo].[ServiceApplications] sa ON sap.[ServiceApplicationId] = sa.[Id]
    INNER JOIN [dbo].[ResourcePermissions] rp ON sap.[ResourcePermissionId] = rp.[Id]
    INNER JOIN [dbo].[Users] u ON sap.[UserId] = u.[UserId]
    WHERE sap.[ServiceApplicationId] = @ServiceAppId
      AND (@UserId IS NULL OR sap.[UserId] = @UserId)
      AND sa.[IsActive] = 1
    ORDER BY sap.[UserId], rp.[PermissionKey];
END;
GO