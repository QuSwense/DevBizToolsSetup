/*
    View: v_ServiceRequestFilesWithDetails
    Description: Comprehensive view of service request files with operation details.
*/
CREATE VIEW [dbo].[v_ServiceRequestFilesWithDetails]
AS
SELECT 
    srf.[Id] AS FileId,
    srf.[ServiceOperationId],
    srf.[FileFormat],
    srf.[Name],
    srf.[IsBaseSnapshot],
    srf.[ParentBaseId],
    srf.[ParentDeltaId],
    srf.[DeltaDepth],
    srf.[UncompressedSizeBytes],
    srf.[CompressionAlgorithmType],
    srf.[ContentHash],
    srf.[RecordVersion],
    srf.[IsActive],
    srf.[CreatedAt],
    srf.[CreatedBy],
    srf.[LastUpdatedAt],
    srf.[LastUpdatedBy],
    
    -- Human readable size
    CASE 
        WHEN srf.[UncompressedSizeBytes] > 1048576 THEN 
            CONVERT(VARCHAR(20), CAST(srf.[UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
        WHEN srf.[UncompressedSizeBytes] > 1024 THEN 
            CONVERT(VARCHAR(20), CAST(srf.[UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
        ELSE 
            CONVERT(VARCHAR(20), srf.[UncompressedSizeBytes]) + ' bytes'
    END AS HumanReadableSize,
    
    -- Operation details
    so.[OperationName],
    so.[HttpMethod],
    so.[EndpointOrAction],
    
    -- Service details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    
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
    DATEDIFF(DAY, srf.[CreatedAt], GETDATE()) AS AgeDays

FROM [dbo].[ServiceRequestFiles] srf
INNER JOIN [dbo].[ServiceOperations] so ON srf.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN [dbo].[ServiceRequestFiles] pb ON srf.[ParentBaseId] = pb.[Id]
LEFT JOIN [dbo].[ServiceRequestFiles] pd ON srf.[ParentDeltaId] = pd.[Id];
GO