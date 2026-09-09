/*
    Stored Procedure: usp_GetServiceRequestFileById
    Description: Gets a service request file by its primary key identifier (int Id).
*/
CREATE PROCEDURE [dbo].[usp_GetServiceRequestFileById]
    @Id INT
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
    WHERE [Id] = @Id;
END;
GO