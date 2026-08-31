/*
    Stored Procedure: usp_GetServiceDefinitionSync
    Description: Gets the latest definition sync record for a service application.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceDefinitionSync]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @IncludeContent BIT = 0  -- Set to 1 to include the compressed content (for performance)
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

    IF @IncludeContent = 1
    BEGIN
        SELECT 
            sds.[Id] AS SyncId,
            sds.[ServiceApplicationId],
            sds.[DefinitionUrl],
            sds.[CompressedContent],  -- Include the full content
            sds.[UncompressedSizeBytes],
            sds.[CompressionAlgorithmType],
            sds.[ContentHash],
            sds.[RecordVersion] AS SyncRecordVersion,
            sds.[CreatedAt] AS SyncCreatedAt,
            sds.[CreatedBy] AS SyncCreatedBy,
            sds.[LastUpdatedAt] AS SyncLastUpdatedAt,
            sds.[LastUpdatedBy] AS SyncLastUpdatedBy,
            sa.[PublicId] AS ServicePublicId,
            sa.[Name] AS ServiceName,
            sa.[ServiceType],
            sa.[BaseUrl],
            sa.[DefinitionType],
            sa.[DefinitionRelativeUrl],
            sa.[HealthcheckRelativeUrl],
            sa.[IsActive] AS ServiceIsActive
        FROM [dbo].[ServiceDefinitionSyncs] sds
        INNER JOIN [dbo].[ServiceApplications] sa ON sds.[ServiceApplicationId] = sa.[Id]
        WHERE sds.[ServiceApplicationId] = @ServiceAppId
        ORDER BY sds.[Id] DESC;
    END
    ELSE
    BEGIN
        -- Exclude the compressed content for better performance
        SELECT 
            sds.[Id] AS SyncId,
            sds.[ServiceApplicationId],
            sds.[DefinitionUrl],
            CAST(0x AS VARBINARY(1)) AS CompressedContent,  -- Placeholder for content
            sds.[UncompressedSizeBytes],
            sds.[CompressionAlgorithmType],
            sds.[ContentHash],
            sds.[RecordVersion] AS SyncRecordVersion,
            sds.[CreatedAt] AS SyncCreatedAt,
            sds.[CreatedBy] AS SyncCreatedBy,
            sds.[LastUpdatedAt] AS SyncLastUpdatedAt,
            sds.[LastUpdatedBy] AS SyncLastUpdatedBy,
            sa.[PublicId] AS ServicePublicId,
            sa.[Name] AS ServiceName,
            sa.[ServiceType],
            sa.[BaseUrl],
            sa.[DefinitionType],
            sa.[DefinitionRelativeUrl],
            sa.[HealthcheckRelativeUrl],
            sa.[IsActive] AS ServiceIsActive
        FROM [dbo].[ServiceDefinitionSyncs] sds
        INNER JOIN [dbo].[ServiceApplications] sa ON sds.[ServiceApplicationId] = sa.[Id]
        WHERE sds.[ServiceApplicationId] = @ServiceAppId
        ORDER BY sds.[Id] DESC;
    END
END;
GO