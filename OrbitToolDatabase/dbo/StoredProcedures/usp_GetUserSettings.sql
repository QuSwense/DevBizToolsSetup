-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Gets user settings with optional filtering
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetUserSettings]
    @UserId NVARCHAR(20) = NULL,
    @GlobalSettingPublicId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GlobalSettingId INT = NULL;

    -- Resolve GlobalSettingPublicId to GlobalSettingId if provided
    IF @GlobalSettingPublicId IS NOT NULL
    BEGIN
        SELECT @GlobalSettingId = [Id]
        FROM [dbo].[GlobalSettings]
        WHERE [PublicId] = @GlobalSettingPublicId;
    END

    SELECT
        us.[Id],
        us.[PublicId],
        us.[GlobalSettingId],
        us.[UserId],
        us.[SettingValue],
        us.[LastUpdatedAt],
        gs.[SettingKey],
        gs.[Category],
        gs.[DataType],
        gs.[Description] AS GlobalSettingDescription,
        CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName
    FROM [dbo].[UserSettings] us
    LEFT JOIN [dbo].[GlobalSettings] gs
        ON us.[GlobalSettingId] = gs.[Id]
    INNER JOIN [dbo].[Users] u
        ON us.[UserId] = u.[UserId]
    WHERE
        (@UserId IS NULL OR us.[UserId] = @UserId)
        AND (@GlobalSettingPublicId IS NULL OR us.[GlobalSettingId] = @GlobalSettingId)
    ORDER BY
        us.[UserId],
        gs.[SettingKey];
END
