/*
    View: v_SoapNamespacesSummary
    Description: Summary of SOAP namespaces per service operation.
*/
CREATE VIEW [dbo].[v_SoapNamespacesSummary]
AS
SELECT 
    so.[Id] AS OperationId,
    so.[OperationName],
    so.[IsActive] AS OperationIsActive,
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
    -- Namespace counts
    COUNT(sn.[Id]) AS TotalNamespaces,
    COUNT(DISTINCT sn.[CompressionAlgorithmType]) AS CompressionTypesUsed,
    SUM(sn.[UncompressedSizeBytes]) AS TotalUncompressedSize,
    
    -- Average size
    AVG(sn.[UncompressedSizeBytes]) AS AvgUncompressedSize,
    
    -- Latest namespace info
    MAX(sn.[CreatedAt]) AS LatestNamespaceCreated,
    MAX(sn.[LastUpdatedAt]) AS LatestNamespaceUpdated,
    MAX(sn.[CreatedBy]) AS LatestNamespaceCreatedBy,
    
    -- Compression distribution
    STUFF((
        SELECT DISTINCT ', ' + sn2.[CompressionAlgorithmType]
        FROM [dbo].[SoapNamespaces] sn2
        INNER JOIN [dbo].[ServiceOperationSchemas] sos2 ON sn2.[ServiceOperationSchemaId] = sos2.[Id]
        WHERE sos2.[ServiceOperationId] = so.[Id]
          AND sn2.[CompressionAlgorithmType] IS NOT NULL
        FOR XML PATH('')
    ), 1, 2, '') AS CompressionTypes,
    
    -- Hash count (unique)
    COUNT(DISTINCT sn.[ContentHash]) AS UniqueHashes

FROM [dbo].[ServiceOperations] so
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[ServiceOperationSchemas] sos ON so.[Id] = sos.[ServiceOperationId]
LEFT JOIN [dbo].[SoapNamespaces] sn ON sos.[Id] = sn.[ServiceOperationSchemaId]
GROUP BY so.[Id], so.[OperationName], so.[IsActive], sa.[PublicId], sa.[Name], sa.[ServiceType];
GO