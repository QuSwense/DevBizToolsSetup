/*
    View: v_SoapNamespacesWithDetails
    Description: Comprehensive view of SOAP namespaces with operation and service details.
*/
CREATE VIEW [dbo].[v_SoapNamespacesWithDetails]
AS
SELECT 
    sn.[Id] AS NamespaceId,
    sn.[ServiceOperationSchemaId],
    sn.[UncompressedSizeBytes],
    sn.[CompressionAlgorithmType],
    sn.[ContentHash],
    sn.[RecordVersion] AS NamespaceRecordVersion,
    sn.[CreatedAt] AS NamespaceCreatedAt,
    sn.[CreatedBy] AS NamespaceCreatedBy,
    sn.[LastUpdatedAt] AS NamespaceLastUpdatedAt,
    sn.[LastUpdatedBy] AS NamespaceLastUpdatedBy,
    
    -- Operation Details
    so.[Id] AS OperationId,
    so.[OperationName],
    so.[EndpointOrAction],
    so.[HttpMethod],
    so.[IsActive] AS OperationIsActive,
    so.[RecordVersion] AS OperationRecordVersion,
    
    -- Schema Details
    sos.[InputRootElementName],
    sos.[OutputRootElementName],
    sos.[TargetNamespace],
    sos.[RecordVersion] AS SchemaRecordVersion,
    sos.[CreatedAt] AS SchemaCreatedAt,
    sos.[CreatedBy] AS SchemaCreatedBy,
    
    -- Service Details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[IsActive] AS ServiceIsActive,
    
    -- Human readable size
    CASE 
        WHEN sn.[UncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(sn.[UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN sn.[UncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(sn.[UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), sn.[UncompressedSizeBytes]) + ' bytes'
    END AS HumanReadableSize,
    
    -- Status
    CASE 
        WHEN sn.[ContentHash] IS NOT NULL THEN 'Valid'
        ELSE 'Invalid'
    END AS NamespaceStatus,
    
    -- Hash short
    LEFT(sn.[ContentHash], 16) + '...' AS ContentHashShort,
    
    -- Age in days
    DATEDIFF(DAY, sn.[CreatedAt], GETDATE()) AS DaysSinceCreation,
    DATEDIFF(DAY, sn.[LastUpdatedAt], GETDATE()) AS DaysSinceLastUpdate

FROM [dbo].[SoapNamespaces] sn
INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id];
GO