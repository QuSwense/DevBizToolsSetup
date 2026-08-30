/*
    View: v_LatestServiceAppAuthentications
    Description: Returns all authentication configurations (both active and inactive) with only the latest version of each.
    Uses PublicId to identify unique configurations across versions.
*/
CREATE VIEW [dbo].[v_LatestServiceAppAuthentications]
AS
WITH LatestAuthConfigs AS (
    -- Get the latest version (highest Id) for each authentication configuration
    SELECT 
        [Id],
        [PublicId],
        [Name],
        [AuthenticationType],
        [EncryptionAlgorithmType],
        [EncryptedJson],
        [IsActive],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy],
        ROW_NUMBER() OVER (PARTITION BY [PublicId] ORDER BY [Id] DESC) AS RowNum,
        COUNT(*) OVER (PARTITION BY [PublicId]) AS TotalVersions
    FROM [dbo].[ServiceAppAuthentications]
)
SELECT 
    -- Configuration Details
    lc.[PublicId] AS AuthenticationId,
    lc.[Id] AS InternalId,
    lc.[Name] AS AuthenticationName,
    lc.[AuthenticationType],
    lc.[EncryptionAlgorithmType],
    lc.[EncryptedJson],
    lc.[IsActive],
    lc.[RecordVersion] AS AuthenticationVersion,
    lc.[CreatedAt] AS AuthCreatedAt,
    lc.[CreatedBy] AS AuthCreatedBy,
    lc.[LastUpdatedAt] AS AuthLastUpdatedAt,
    lc.[LastUpdatedBy] AS AuthLastUpdatedBy,
    
    -- Version Metadata
    lc.[TotalVersions] AS TotalVersions,
    CASE 
        WHEN lc.[IsActive] = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS StatusDescription,
    
    -- Helper fields for UI
    CASE 
        WHEN lc.[IsActive] = 1 
        THEN CONCAT(lc.[Name], ' (Active)')
        ELSE CONCAT(lc.[Name], ' (Inactive)')
    END AS DisplayName,
    
    -- Count of service applications using this auth config
    (
        SELECT COUNT(*) 
        FROM [dbo].[ServiceApplications] sa
        WHERE sa.[ServiceAppAuthenticationId] = lc.[Id]
          AND sa.[IsActive] = 1
    ) AS ActiveServiceCount,
    
    (
        SELECT COUNT(*) 
        FROM [dbo].[ServiceApplications] sa
        WHERE sa.[ServiceAppAuthenticationId] = lc.[Id]
    ) AS TotalServiceCount,
    
    -- Check if this auth is in use by any active service
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceApplications] sa
            WHERE sa.[ServiceAppAuthenticationId] = lc.[Id]
              AND sa.[IsActive] = 1
        ) THEN 1
        ELSE 0
    END AS IsInUse
FROM LatestAuthConfigs lc
WHERE lc.RowNum = 1;  -- Only the latest version per PublicId
GO