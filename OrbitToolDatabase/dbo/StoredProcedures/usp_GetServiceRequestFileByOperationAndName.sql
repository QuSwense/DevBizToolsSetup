/*
    Stored Procedure: usp_GetServiceRequestFileByOperationAndName
    Description: Gets an active service request file by operation ID and file name.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceRequestFileByOperationAndName]
    @ServiceOperationId INT,
    @Name NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id],
        [ServiceOperationId],
        [FileFormat],
        [Name],
        [IsBaseSnapshot],
        [ParentBaseId],
        [ParentDeltaId],
        [DeltaDepth],
        [CompressedData],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [ContentHash],
        [RecordVersion],
        [IsActive],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy]
    FROM [dbo].[ServiceRequestFiles]
    WHERE [ServiceOperationId] = @ServiceOperationId
      AND [Name] = @Name
      AND [IsActive] = 1;
END;
GO