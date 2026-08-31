/*
    Stored Procedure: usp_GetServiceResponseFilesByRequest
    Description: Gets all response files for a specific request file.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceResponseFilesByRequest]
    @RequestFileId INT,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [Id] AS ResponseFileId,
        [ServiceRequestFileId],
        [FileFormat],
        [Name],
        [IsBaseSnapshot],
        [ParentBaseId],
        [ParentDeltaId],
        [DeltaDepth],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [FileHash],
        [RecordVersion],
        [IsActive],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy],
        
        -- Chain info
        CASE 
            WHEN [IsBaseSnapshot] = 1 THEN 'Base'
            WHEN [DeltaDepth] = 1 THEN 'Direct Delta'
            ELSE 'Nested Delta (Depth: ' + CAST([DeltaDepth] AS NVARCHAR(10)) + ')'
        END AS FileTypeDescription,
        
        -- Parent info
        (SELECT [Name] FROM [dbo].[ServiceResponseFiles] WHERE [Id] = [ParentBaseId]) AS ParentBaseName,
        (SELECT [Name] FROM [dbo].[ServiceResponseFiles] WHERE [Id] = [ParentDeltaId]) AS ParentDeltaName,
        
        -- Human readable size
        CASE 
            WHEN [UncompressedSizeBytes] > 1048576 THEN 
                CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1048576.0 AS DECIMAL(10,2))) + ' MB'
            WHEN [UncompressedSizeBytes] > 1024 THEN 
                CONVERT(VARCHAR(20), CAST([UncompressedSizeBytes] / 1024.0 AS DECIMAL(10,2))) + ' KB'
            ELSE 
                CONVERT(VARCHAR(20), [UncompressedSizeBytes]) + ' bytes'
        END AS HumanReadableSize
        
    FROM [dbo].[ServiceResponseFiles]
    WHERE [ServiceRequestFileId] = @RequestFileId
      AND (@IncludeInactive = 1 OR [IsActive] = 1)
    ORDER BY [CreatedAt] DESC;
END;
GO