-- User settings with global setting details
CREATE VIEW [dbo].[v_UserSettingsWithDetails]
AS
SELECT
    us.Id,
    us.PublicId,
    us.GlobalSettingId,
    us.UserId,
    us.SettingValue,
    us.LastUpdatedAt,
    -- Global setting details
    gs.SettingKey,
    gs.Category,
    gs.DataType,
    gs.Description AS GlobalSettingDescription,
    gs.IsUserOverridable,
    -- User details
    CONCAT(u.FirstName, ' ', u.LastName) AS UserFullName,
    u.Email AS UserEmail,
    -- Computed flags
    1 AS IsOverridden,
    CASE WHEN gs.Id IS NOT NULL THEN 1 ELSE 0 END AS HasGlobalDefault
FROM [dbo].[UserSettings] us
LEFT JOIN [dbo].[GlobalSettings] gs ON us.GlobalSettingId = gs.Id
INNER JOIN [dbo].[Users] u ON us.UserId = u.UserId;
GO
