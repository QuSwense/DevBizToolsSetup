-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Gets all global settings with optional filtering
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetGlobalSettings]
    @Category NVARCHAR(50) = NULL,
    @IncludeInactive BIT = 0,
    @SettingKey NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        gs.[Id],
        gs.[PublicId],
        gs.[Category],
        gs.[SettingKey],
        gs.[SettingValue],
        gs.[DataType],
        gs.[Description],
        gs.[IsUserOverridable],
        gs.[IsActive],
        gs.[CreatedAt],
        gs.[CreatedBy],
        gs.[LastUpdatedAt],
        gs.[LastUpdatedBy],
        ISNULL(uc.[UserOverrideCount], 0) AS UserOverrideCount
    FROM [dbo].[GlobalSettings] gs
    OUTER APPLY (
        SELECT COUNT(*) AS UserOverrideCount
        FROM [dbo].[UserSettings] us
        WHERE us.[GlobalSettingId] = gs.[Id]
    ) uc
    WHERE
        (@Category IS NULL OR gs.[Category] = @Category)
        AND (@IncludeInactive = 1 OR gs.[IsActive] = 1)
        AND (@SettingKey IS NULL OR gs.[SettingKey] = @SettingKey)
    ORDER BY
        gs.[Category],
        gs.[SettingKey];
END
