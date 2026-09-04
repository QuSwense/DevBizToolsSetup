/*
    View: v_ServiceResponseFilesWithDetails
    Description: Comprehensive view of service response files with request and operation details.
*/
CREATE VIEW [dbo].[v_ServiceResponseFilesWithDetails]
AS
SELECT 
    srf.[Id] AS ResponseFileId,
    srf.[ServiceRequestFileId],
    srf.[FileFormat],
    srf.[Name] AS ResponseFileName,
    srf.[IsBaseSnapshot],
    srf.[ParentBaseId],
    srf.[ParentDeltaId],
    srf.[DeltaDepth],
    srf.[UncompressedSizeBytes] AS ResponseSize,
    srf.[CompressionAlgorithmType] AS ResponseCompression,
    srf.[ContentHash] AS ResponseFileHash,
    srf.[RecordVersion] AS ResponseRecordVersion,
    srf.[IsActive] AS ResponseIsActive,
    srf.[CreatedAt] AS ResponseCreatedAt,
    srf.[CreatedBy] AS ResponseCreatedBy,
    srf.[LastUpdatedAt] AS ResponseLastUpdatedAt,
    srf.[LastUpdatedBy] AS ResponseLastUpdatedBy,
    
    -- Request details
    req.[Id] AS RequestFileId,
    req.[Name] AS RequestFileName,
    req.[FileFormat] AS RequestFileFormat,
    req.[IsBaseSnapshot] AS RequestIsBase,
    req.[UncompressedSizeBytes] AS RequestSize,
    req.[ContentHash] AS RequestFileHash,
    
    -- Operation details
    so.[Id] AS OperationId,
    so.[OperationName],
    so.[HttpMethod],
    so.[EndpointOrAction],
    so.[Description] AS OperationDescription,
    
    -- Service details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
    -- Human readable size
    CASE 
        WHEN srf.[UncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(srf.[UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN srf.[UncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(srf.[UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), srf.[UncompressedSizeBytes]) + ' bytes'
    END AS HumanReadableSize,
    
    -- Chain info
    CASE 
        WHEN srf.[IsBaseSnapshot] = 1 THEN 'Base Snapshot'
        WHEN srf.[DeltaDepth] = 1 THEN 'Direct Delta'
        ELSE 'Nested Delta'
    END AS FileTypeDescription,
    
    -- Parent info
    pb.[Name] AS ParentBaseName,
    pd.[Name] AS ParentDeltaName,
    
    -- Hash short
    LEFT(srf.[ContentHash], 16) + '...' AS HashShort,
    
    -- Status
    CASE 
        WHEN srf.[IsActive] = 1 AND srf.[IsBaseSnapshot] = 1 THEN 'Active Base'
        WHEN srf.[IsActive] = 1 AND srf.[IsBaseSnapshot] = 0 THEN 'Active Delta'
        ELSE 'Inactive'
    END AS StatusDescription,
    
    -- Age
    DATEDIFF(DAY, srf.[CreatedAt], GETDATE()) AS AgeDays,
    
    -- Request-Response pairing info
    CONCAT(req.[Name], ' -> ', srf.[Name]) AS RequestResponsePair

FROM [dbo].[ServiceResponseFiles] srf
INNER JOIN [dbo].[ServiceRequestFiles] req ON srf.[ServiceRequestFileId] = req.[Id]
INNER JOIN [dbo].[ServiceOperations] so ON req.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] pb ON srf.[ParentBaseId] = pb.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] pd ON srf.[ParentDeltaId] = pd.[Id];
GO