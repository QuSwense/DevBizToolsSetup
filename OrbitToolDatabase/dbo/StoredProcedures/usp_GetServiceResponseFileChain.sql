/*
    Stored Procedure: usp_GetServiceResponseFileChain
    Description: Gets a response file with its complete delta chain (base + all deltas).
*/
CREATE PROCEDURE [dbo].[usp_GetServiceResponseFileChain]
    @ResponseFileId INT,
    @IncludeData BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BaseId INT;
    DECLARE @CurrentId INT = @ResponseFileId;
    DECLARE @Depth INT;

    -- Get the base ID for this file
    SELECT 
        @BaseId = CASE WHEN [IsBaseSnapshot] = 1 THEN [Id] ELSE [ParentBaseId] END,
        @Depth = [DeltaDepth]
    FROM [dbo].[ServiceResponseFiles]
    WHERE [Id] = @ResponseFileId
      AND [IsActive] = 1;

    IF @BaseId IS NULL
    BEGIN
        RAISERROR('Response file with Id %d not found or inactive.', 16, 1, @ResponseFileId);
        RETURN;
    END;

    -- Build the chain using a recursive CTE
    WITH DeltaChain AS (
        SELECT 
            [Id],
            [ServiceRequestFileId],
            [IsBaseSnapshot],
            [ParentBaseId],
            [ParentDeltaId],
            [DeltaDepth],
            [Name],
            [FileFormat],
            [CompressedData],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [CreatedAt],
            [CreatedBy],
            0 AS ChainPosition
        FROM [dbo].[ServiceResponseFiles]
        WHERE [Id] = @BaseId
          AND [IsActive] = 1

        UNION ALL

        SELECT 
            srf.[Id],
            srf.[ServiceRequestFileId],
            srf.[IsBaseSnapshot],
            srf.[ParentBaseId],
            srf.[ParentDeltaId],
            srf.[DeltaDepth],
            srf.[Name],
            srf.[FileFormat],
            srf.[CompressedData],
            srf.[UncompressedSizeBytes],
            srf.[CompressionAlgorithmType],
            srf.[ContentHash],
            srf.[CreatedAt],
            srf.[CreatedBy],
            dc.ChainPosition + 1
        FROM [dbo].[ServiceResponseFiles] srf
        INNER JOIN DeltaChain dc ON srf.[ParentDeltaId] = dc.[Id]
        WHERE srf.[IsActive] = 1
          AND srf.[IsBaseSnapshot] = 0
    )
    SELECT 
        [Id] AS ResponseFileId,
        [ServiceRequestFileId],
        [IsBaseSnapshot],
        [ParentBaseId],
        [ParentDeltaId],
        [DeltaDepth],
        [Name],
        [FileFormat],
        CASE WHEN @IncludeData = 1 THEN [CompressedData] ELSE CAST(0x AS VARBINARY(1)) END AS CompressedData,
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [ContentHash],
        [CreatedAt],
        [CreatedBy],
        ChainPosition,
        CASE 
            WHEN ChainPosition = 0 THEN 'Base'
            WHEN ChainPosition = (SELECT MAX(ChainPosition) FROM DeltaChain) THEN 'Latest Delta'
            ELSE 'Delta'
        END AS ChainPositionDescription,
        (SELECT MAX(ChainPosition) FROM DeltaChain) AS TotalChainLength
    FROM DeltaChain
    ORDER BY ChainPosition ASC;
END;
GO