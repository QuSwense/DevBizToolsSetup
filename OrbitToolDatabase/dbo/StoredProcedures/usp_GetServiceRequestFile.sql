/*
    Stored Procedure: usp_GetServiceRequestFile

    Retrieves a single request file by Id or PublicId,
    optionally including its embedding links and/or content.
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceRequestFile]
    @ServiceRequestFileId       INT = NULL,
    @PublicId                   UNIQUEIDENTIFIER = NULL,
    @IncludeContent             BIT = 0,
    @IncludeLinks               BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @ServiceRequestFileId IS NULL AND @PublicId IS NULL
        RAISERROR('Provide ServiceRequestFileId or PublicId.', 16, 1);

    SELECT
        f.[Id]                      AS ServiceRequestFileId,
        f.[PublicId],
        f.[ServiceOperationId],
        f.[FileFormat],
        f.[Name],
        CASE WHEN @IncludeContent = 1 THEN f.[CompressedData] END AS CompressedData,
        f.[UncompressedSizeBytes],
        f.[CompressionAlgorithmType],
        f.[RecordVersion],
        f.[IsActive],
        f.[CreatedAt],
        f.[CreatedBy]
    FROM [dbo].[ServiceRequestFiles] f
    WHERE (@ServiceRequestFileId IS NULL OR f.[Id] = @ServiceRequestFileId)
      AND (@PublicId IS NULL OR f.[PublicId] = @PublicId);

    IF @IncludeLinks = 1
    BEGIN
        SELECT
            l.[Id]                      AS LinkId,
            l.[PublicId],
            l.[ServiceRequestFileId],
            l.[ElementName],
            l.[XmlPath],
            l.[BinaryEmbeddingsStoreId],
            l.[Name],
            l.[AdditionalDetails],
            l.[CreatedAt],
            l.[CreatedBy]
        FROM [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks] l
        INNER JOIN [dbo].[ServiceRequestFiles] f
            ON f.[Id] = l.[ServiceRequestFileId]
        WHERE (@ServiceRequestFileId IS NULL OR f.[Id] = @ServiceRequestFileId)
          AND (@PublicId IS NULL OR f.[PublicId] = @PublicId)
        ORDER BY l.[Id];
    END
END;
GO
