/*
    View: v_ServiceDefinitionSyncsWithDetails
    Description: Comprehensive view of service definition syncs with service details.
*/
CREATE VIEW [dbo].[v_ServiceDefinitionSyncsWithDetails]
AS
SELECT 
    sds.[Id] AS SyncId,
    sds.[ServiceApplicationId],
    sds.[DefinitionUrl],
    sds.[UncompressedSizeBytes],
    sds.[CompressionAlgorithmType],
    sds.[ContentHash],
    sds.[RecordVersion] AS SyncRecordVersion,
    sds.[CreatedAt] AS SyncCreatedAt,
    sds.[CreatedBy] AS SyncCreatedBy,
    sds.[LastUpdatedAt] AS SyncLastUpdatedAt,
    sds.[LastUpdatedBy] AS SyncLastUpdatedBy,
    
    -- Service Details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[DefinitionType],
    sa.[DefinitionRelativeUrl],
    sa.[HealthcheckRelativeUrl],
    sa.[IsActive] AS ServiceIsActive,
    sa.[RecordVersion] AS ServiceRecordVersion,
    
    -- Derived fields
    CASE 
        WHEN sds.[UncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(sds.[UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN sds.[UncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(sds.[UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), sds.[UncompressedSizeBytes]) + ' bytes'
    END AS HumanReadableSize,
    
    -- Date difference
    DATEDIFF(DAY, sds.[CreatedAt], GETDATE()) AS DaysSinceSync,
    DATEDIFF(HOUR, sds.[CreatedAt], GETDATE()) AS HoursSinceSync,
    
    -- File hash short version for display
    LEFT(sds.[ContentHash], 16) + '...' AS ContentHashShort,
    
    -- Sync status
    CASE 
        WHEN sds.[ContentHash] IS NOT NULL THEN 'Synced'
        ELSE 'Not Synced'
    END AS SyncStatus

FROM [dbo].[ServiceDefinitionSyncs] sds
INNER JOIN [dbo].[ServiceApplications] sa ON sds.[ServiceApplicationId] = sa.[Id]
WHERE sa.[IsActive] = 1;
GO