CREATE VIEW [dbo].[v_LatestServiceApplicationsWithAuth]
AS
WITH LatestServiceApps AS (
    SELECT 
        [Id],
        [PublicId],  -- Add this
        [ServiceType],
        [ServiceAppAuthenticationId],
        [Name],
        [BaseUrl],
        [DefinitionType],
        [DefinitionRelativeUrl],
        [HealthcheckRelativeUrl],
        [Description],
        [IsActive],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy],
        ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Id] DESC) AS RowNum
    FROM [dbo].[ServiceApplications]
)
SELECT 
    -- Use PublicId instead of Id for external references
    sa.[PublicId] AS ServiceApplicationId,  -- This is what UI uses
    sa.[Id] AS InternalId,  -- Optional: for debugging only
    sa.[ServiceType],
    sa.[Name] AS ServiceApplicationName,
    sa.[BaseUrl],
    sa.[DefinitionType],
    sa.[DefinitionRelativeUrl],
    sa.[HealthcheckRelativeUrl],
    sa.[Description],
    sa.[IsActive],
    sa.[RecordVersion] AS ServiceApplicationVersion,
    sa.[CreatedAt] AS ServiceAppCreatedAt,
    sa.[CreatedBy] AS ServiceAppCreatedBy,
    sa.[LastUpdatedAt] AS ServiceAppLastUpdatedAt,
    sa.[LastUpdatedBy] AS ServiceAppLastUpdatedBy,
    
    -- Authentication
    auth.[PublicId] AS AuthenticationId,
    auth.[Name] AS AuthenticationName,
    auth.[AuthenticationType],
    auth.[EncryptionAlgorithmType],
    auth.[RecordVersion] AS AuthenticationVersion,
    auth.[CreatedAt] AS AuthCreatedAt,
    auth.[CreatedBy] AS AuthCreatedBy,
    auth.[LastUpdatedAt] AS AuthLastUpdatedAt,
    auth.[LastUpdatedBy] AS AuthLastUpdatedBy,
    
    CASE WHEN auth.[Id] IS NOT NULL THEN 1 ELSE 0 END AS HasAuthentication
FROM LatestServiceApps sa
LEFT JOIN [dbo].[ServiceAppAuthentications] auth 
    ON sa.[ServiceAppAuthenticationId] = auth.[Id]
    AND auth.[IsActive] = 1
WHERE sa.RowNum = 1;
GO