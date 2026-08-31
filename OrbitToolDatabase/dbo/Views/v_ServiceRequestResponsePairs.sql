/*
    View: v_ServiceRequestResponsePairs
    Description: Shows the relationship between request and response files.
*/
CREATE VIEW [dbo].[v_ServiceRequestResponsePairs]
AS
SELECT 
    req.[Id] AS RequestFileId,
    req.[Name] AS RequestFileName,
    req.[FileFormat] AS RequestFileFormat,
    req.[CreatedAt] AS RequestCreatedAt,
    req.[UncompressedSizeBytes] AS RequestSize,
    
    resp.[Id] AS ResponseFileId,
    resp.[Name] AS ResponseFileName,
    resp.[FileFormat] AS ResponseFileFormat,
    resp.[IsBaseSnapshot] AS ResponseIsBase,
    resp.[DeltaDepth] AS ResponseDeltaDepth,
    resp.[CreatedAt] AS ResponseCreatedAt,
    resp.[UncompressedSizeBytes] AS ResponseSize,
    
    -- Operation details
    so.[OperationName],
    so.[HttpMethod],
    so.[EndpointOrAction],
    
    -- Service details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
    -- Time difference
    DATEDIFF(SECOND, req.[CreatedAt], resp.[CreatedAt]) AS ResponseTimeSeconds,
    DATEDIFF(MILLISECOND, req.[CreatedAt], resp.[CreatedAt]) AS ResponseTimeMilliseconds,
    
    -- Total size
    req.[UncompressedSizeBytes] + resp.[UncompressedSizeBytes] AS TotalSize,
    
    -- Status
    CASE 
        WHEN resp.[Id] IS NULL THEN 'No Response'
        WHEN resp.[IsActive] = 1 THEN 'Active Response'
        ELSE 'Inactive Response'
    END AS PairStatus

FROM [dbo].[ServiceRequestFiles] req
INNER JOIN [dbo].[ServiceOperations] so ON req.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] resp ON req.[Id] = resp.[ServiceRequestFileId] AND resp.[IsActive] = 1
WHERE req.[IsActive] = 1;
GO