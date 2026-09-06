-- Global settings with user override counts
CREATE VIEW [dbo].[v_GlobalSettingsWithDetails]
AS
SELECT
    gs.Id,
    gs.PublicId,
    gs.Category,
    gs.SettingKey,
    gs.SettingValue,
    gs.DataType,
    gs.Description,
    gs.IsUserOverridable,
    gs.IsActive,
    gs.CreatedAt,
    gs.CreatedBy,
    gs.LastUpdatedAt,
    gs.LastUpdatedBy,
    -- User override statistics
    (SELECT COUNT(*) FROM [dbo].[UserSettings] us WHERE us.GlobalSettingId = gs.Id) AS UserOverrideCount,
    CASE WHEN (SELECT COUNT(*) FROM [dbo].[UserSettings] us WHERE us.GlobalSettingId = gs.Id) > 0 THEN 1 ELSE 0 END AS IsOverridden,
    -- Human-readable data type description
    CASE gs.DataType
        WHEN 'String' THEN 'Text value'
        WHEN 'Int' THEN 'Whole number'
        WHEN 'Decimal' THEN 'Decimal number'
        WHEN 'Bool' THEN 'True/False flag'
        WHEN 'Json' THEN 'JSON object'
        WHEN 'DateTime' THEN 'Date and time value'
        ELSE 'Unknown type'
    END AS DataTypeDescription,
    -- Age in days since creation
    DATEDIFF(DAY, gs.CreatedAt, GETDATE()) AS AgeDays
FROM [dbo].[GlobalSettings] gs;
GO
