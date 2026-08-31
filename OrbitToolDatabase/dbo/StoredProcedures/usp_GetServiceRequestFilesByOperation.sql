/*
    Stored Procedure: usp_GetServiceRequestFilesByOperation
    Description: Gets all files for a specific operation with optional filtering.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceRequestFilesByOperation]
    @OperationId INT,
    @IncludeInactive BIT = 0,
    @FileType VARCHAR(10) = NULL, -- 'Base', 'Delta', 'All'
    @NameFilter NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [Id] AS FileId,
        [ServiceOperationId],
        [FileFormat],
        [Name],
        [IsBaseSnapshot],
        [ParentBaseId],
        [ParentDeltaId],
        [DeltaDepth],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [ContentHash],
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
        (SELECT [Name] FROM [dbo].[ServiceRequestFiles] WHERE [Id] = [ParentBaseId]) AS ParentBaseName,
        (SELECT [Name] FROM [dbo].[ServiceRequestFiles] WHERE [Id] = [ParentDeltaId]) AS ParentDeltaName
        
    FROM [dbo].[ServiceRequestFiles]
    WHERE [ServiceOperationId] = @OperationId
      AND (@IncludeInactive = 1 OR [IsActive] = 1)
      AND (@NameFilter IS NULL OR [Name] LIKE '%' + @NameFilter + '%')
      AND (@FileType IS NULL OR 
           (@FileType = 'Base' AND [IsBaseSnapshot] = 1) OR
           (@FileType = 'Delta' AND [IsBaseSnapshot] = 0) OR
           (@FileType = 'All'))
    ORDER BY [CreatedAt] DESC;
END;
GO