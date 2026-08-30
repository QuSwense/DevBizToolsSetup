/*
    Stored Procedure: usp_GetServiceApplicationHistory
    Description: Gets the complete version history for a single service application including current version.
    Includes authentication details and usage statistics for each version.
    
    Parameters:
        @PublicId UNIQUEIDENTIFIER - The PublicId of the service application
        @IncludeAuthDetails BIT = 1 - Whether to include authentication details
        @IncludeServiceUsage BIT = 1 - Whether to include service usage statistics
*/
CREATE PROCEDURE [dbo].[usp_GetServiceApplicationHistory]
    @PublicId UNIQUEIDENTIFIER,
    @IncludeAuthDetails BIT = 1,
    @IncludeServiceUsage BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Get all versions of the service application
    WITH ServiceVersions AS (
        SELECT 
            [Id],
            [PublicId],
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
            -- Version metadata
            ROW_NUMBER() OVER (PARTITION BY [PublicId] ORDER BY [Id] DESC) AS VersionNumber,
            COUNT(*) OVER (PARTITION BY [PublicId]) AS TotalVersions,
            -- Previous version info
            LAG([RecordVersion]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) AS PreviousVersion,
            LAG([Id]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) AS PreviousVersionId,
            -- Next version info
            LEAD([RecordVersion]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) AS NextVersion,
            LEAD([Id]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) AS NextVersionId,
            -- Version difference in days
            DATEDIFF(DAY, 
                LAG([CreatedAt]) OVER (PARTITION BY [PublicId] ORDER BY [Id]), 
                [CreatedAt]
            ) AS DaysSincePreviousVersion,
            -- Version difference in hours
            DATEDIFF(HOUR, 
                LAG([CreatedAt]) OVER (PARTITION BY [PublicId] ORDER BY [Id]), 
                [CreatedAt]
            ) AS HoursSincePreviousVersion,
            -- Check if URL changed from previous version
            CASE 
                WHEN LAG([BaseUrl]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) IS NULL THEN 0
                WHEN LAG([BaseUrl]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) <> [BaseUrl] THEN 1
                WHEN LAG([DefinitionRelativeUrl]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) <> [DefinitionRelativeUrl] THEN 1
                WHEN LAG([HealthcheckRelativeUrl]) OVER (PARTITION BY [PublicId] ORDER BY [Id]) <> [HealthcheckRelativeUrl] THEN 1
                ELSE 0
            END AS UrlChanged
        FROM [dbo].[ServiceApplications]
        WHERE [PublicId] = @PublicId
    )
    SELECT 
        -- Basic Information
        sv.[Id] AS VersionId,
        sv.[PublicId],
        sv.[VersionNumber],
        sv.[TotalVersions],
        CASE 
            WHEN sv.[VersionNumber] = 1 THEN 1 
            ELSE 0 
        END AS IsLatestVersion,
        sv.[Name] AS ServiceName,
        sv.[ServiceType],
        sv.[BaseUrl],
        sv.[DefinitionType],
        sv.[DefinitionRelativeUrl],
        sv.[HealthcheckRelativeUrl],
        sv.[Description],
        sv.[IsActive],
        sv.[RecordVersion],
        
        -- Version Comparison
        sv.[PreviousVersion],
        sv.[PreviousVersionId],
        sv.[NextVersion],
        sv.[NextVersionId],
        sv.[DaysSincePreviousVersion],
        sv.[HoursSincePreviousVersion],
        sv.[UrlChanged],
        CASE 
            WHEN sv.[UrlChanged] = 1 THEN 'URL Change'
            WHEN sv.[VersionNumber] = sv.[TotalVersions] THEN 'Current Version'
            ELSE 'In-Place Update'
        END AS ChangeType,
        
        -- Audit Details
        sv.[CreatedAt] AS VersionCreatedAt,
        sv.[CreatedBy] AS VersionCreatedBy,
        sv.[LastUpdatedAt] AS VersionLastUpdatedAt,
        sv.[LastUpdatedBy] AS VersionLastUpdatedBy,
        
        -- Authentication Details (if requested)
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[PublicId]
            ELSE NULL
        END AS AuthenticationId,
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[Name]
            ELSE NULL
        END AS AuthenticationName,
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[AuthenticationType]
            ELSE NULL
        END AS AuthenticationType,
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[EncryptionAlgorithmType]
            ELSE NULL
        END AS EncryptionAlgorithmType,
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[RecordVersion]
            ELSE NULL
        END AS AuthRecordVersion,
        CASE 
            WHEN @IncludeAuthDetails = 1 THEN auth.[IsActive]
            ELSE NULL
        END AS AuthIsActive,
        
        -- Service Usage (if requested)
        CASE 
            WHEN @IncludeServiceUsage = 1 THEN (
                SELECT COUNT(*) 
                FROM [dbo].[ServiceApplications] sa
                WHERE sa.[Name] = sv.[Name]
                  AND sa.[IsActive] = 1
                  AND sa.[PublicId] != sv.[PublicId]
            )
            ELSE NULL
        END AS OtherActiveVersionsCount,
        
        -- Change summary (human readable)
        CASE 
            WHEN sv.[VersionNumber] = 1 AND sv.[TotalVersions] = 1 THEN 'Initial Creation'
            WHEN sv.[VersionNumber] = sv.[TotalVersions] AND sv.[IsActive] = 1 THEN 'Current Active Version'
            WHEN sv.[VersionNumber] = sv.[TotalVersions] AND sv.[IsActive] = 0 THEN 'Current Version (Inactive)'
            WHEN sv.[IsActive] = 1 AND sv.[VersionNumber] < sv.[TotalVersions] THEN 'Previous Active Version'
            WHEN sv.[IsActive] = 0 AND sv.[VersionNumber] < sv.[TotalVersions] THEN 'Archived Version'
            ELSE 'Historical Version'
        END AS VersionStatus,
        
        -- Has changes summary
        CASE 
            WHEN sv.[UrlChanged] = 1 THEN 'URL and/or Definition changes'
            WHEN sv.[VersionNumber] = 1 AND sv.[TotalVersions] > 1 THEN 'Initial Version'
            WHEN sv.[VersionNumber] = sv.[TotalVersions] THEN 'Current Version'
            ELSE 'Metadata changes (Name, Description, etc.)'
        END AS ChangeSummary

    FROM ServiceVersions sv
    LEFT JOIN [dbo].[ServiceAppAuthentications] auth 
        ON sv.[ServiceAppAuthenticationId] = auth.[Id]
    ORDER BY sv.[Id] DESC;  -- Newest first
END;
GO