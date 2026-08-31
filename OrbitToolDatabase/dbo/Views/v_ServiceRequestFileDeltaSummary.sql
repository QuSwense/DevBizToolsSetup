/*
    View: v_ServiceRequestFileDeltaSummary
    Description: Summary of delta chains per base file.
*/
CREATE VIEW [dbo].[v_ServiceRequestFileDeltaSummary]
AS
WITH DeltaStats AS (
    SELECT 
        [ParentBaseId] AS BaseFileId,
        COUNT(*) AS TotalDeltas,
        MAX([DeltaDepth]) AS MaxDepth,
        MIN([CreatedAt]) AS FirstDeltaCreated,
        MAX([CreatedAt]) AS LastDeltaCreated,
        SUM([UncompressedSizeBytes]) AS TotalDeltaSize,
        COUNT(DISTINCT [Name]) AS UniqueDeltaNames
    FROM [dbo].[ServiceRequestFiles]
    WHERE [IsBaseSnapshot] = 0
      AND [IsActive] = 1
    GROUP BY [ParentBaseId]
)
SELECT 
    b.[Id] AS BaseFileId,
    b.[Name] AS BaseFileName,
    b.[FileFormat],
    b.[UncompressedSizeBytes] AS BaseSize,
    b.[CreatedAt] AS BaseCreatedAt,
    b.[ContentHash] AS BaseHash,
    
    -- Delta stats
    ds.[TotalDeltas],
    ds.[MaxDepth],
    ds.[FirstDeltaCreated],
    ds.[LastDeltaCreated],
    ds.[TotalDeltaSize],
    ds.[UniqueDeltaNames],
    
    -- Total size (base + all deltas)
    b.[UncompressedSizeBytes] + ISNULL(ds.[TotalDeltaSize], 0) AS TotalSize,
    
    -- Savings
    CASE 
        WHEN ds.[TotalDeltas] > 0 THEN
            ((b.[UncompressedSizeBytes] * (ds.[TotalDeltas] + 1)) - (b.[UncompressedSizeBytes] + ds.[TotalDeltaSize]))
        ELSE 0
    END AS StorageSavingsBytes,
    
    -- Efficiency
    CASE 
        WHEN ds.[TotalDeltas] > 0 AND b.[UncompressedSizeBytes] > 0 THEN
            CAST(
                ((b.[UncompressedSizeBytes] * (ds.[TotalDeltas] + 1)) - (b.[UncompressedSizeBytes] + ds.[TotalDeltaSize])) * 100.0 
                / (b.[UncompressedSizeBytes] * (ds.[TotalDeltas] + 1))
                AS DECIMAL(10,2)
            )
        ELSE 0
    END AS StorageSavingsPercent,
    
    -- Operation details
    so.[OperationName],
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName

FROM [dbo].[ServiceRequestFiles] b
INNER JOIN [dbo].[ServiceOperations] so ON b.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
LEFT JOIN DeltaStats ds ON b.[Id] = ds.[BaseFileId]
WHERE b.[IsBaseSnapshot] = 1
  AND b.[IsActive] = 1;
GO