/*
    View: v_ServiceApplicationAudit
    Description: Provides a comprehensive view of all service application audit logs with user details.
*/
CREATE VIEW [dbo].[v_ServiceApplicationAudit]
AS
SELECT 
    ua.[Id] AS AuditId,
    ua.[UserId],
    u.[FullName] AS UserFullName,
    u.[Email] AS UserEmail,
    ua.[ActivityType],
    ua.[ActionType],
    ua.[FeatureActivitiesJson],
    ua.[Timestamp],
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.ServiceId') AS ServicePublicId,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.ServiceName') AS ServiceName,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.ChangeType') AS ChangeType,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.OldVersion') AS OldVersion,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.NewVersion') AS NewVersion,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.Message') AS ChangeMessage,
    JSON_VALUE(ua.[FeatureActivitiesJson], '$.Notes') AS Notes,
    CASE 
        WHEN ua.[ActionType] = 'Create' THEN 'Created'
        WHEN ua.[ActionType] = 'VersionUpdate' THEN 'Version Updated'
        WHEN ua.[ActionType] = 'InPlaceUpdate' THEN 'Details Updated'
        WHEN ua.[ActionType] = 'StatusToggle' THEN 'Status Toggled'
        ELSE 'Unknown'
    END AS ActionDescription,
    DATEDIFF(HOUR, ua.[Timestamp], GETDATE()) AS HoursAgo,
    FORMAT(ua.[Timestamp], 'yyyy-MM-dd HH:mm:ss') AS FormattedTimestamp
FROM [dbo].[UserActivities] ua
LEFT JOIN [dbo].[Users] u ON ua.[UserId] = u.[UserId]
WHERE ua.[ActivityType] LIKE 'ServiceApplication%'
ORDER BY ua.[Timestamp] DESC;
GO