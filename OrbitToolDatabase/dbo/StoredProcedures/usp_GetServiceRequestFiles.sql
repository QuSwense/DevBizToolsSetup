/*
    Stored Procedure: usp_GetServiceRequestFiles

    Returns request files for a given service operation.
    @IncludePreviousVersions = 0 → latest version of each file name only
    @IncludePreviousVersions = 1 → full history
    @IncludeContent          = 0 → metadata only
    @IncludeContent          = 1 → include CompressedData
    @IncludeLinks            = 1 → also return a second result set with embedding links
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceRequestFiles]
    @ServiceOperationId         INT,
    @IncludePreviousVersions    BIT = 0,
    @IncludeContent             BIT = 0,
    @IncludeLinks               BIT = 0,
    @Name                       NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceOperations] WHERE [Id] = @ServiceOperationId)
        RAISERROR('Service operation was not found.', 16, 1);

    ;WITH Ranked AS
    (
        SELECT
            f.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY f.[ServiceOperationId], f.[Name]
                ORDER BY f.[Id] DESC
            ) AS rn
        FROM [dbo].[ServiceRequestFiles] f
        WHERE f.[ServiceOperationId] = @ServiceOperationId
          AND (@Name IS NULL OR f.[Name] = @Name)
    )
    SELECT
        [Id]                        AS ServiceRequestFileId,
        [PublicId],
        [ServiceOperationId],
        [FileFormat],
        [Name],
        CASE WHEN @IncludeContent = 1 THEN [CompressedData] END AS CompressedData,
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [RecordVersion],
        [IsActive],
        [CreatedAt],
        [CreatedBy],
        CASE WHEN rn = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsLatest
    FROM Ranked
    WHERE @IncludePreviousVersions = 1 OR rn = 1
    ORDER BY [Name], [Id] DESC;

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
        WHERE f.[ServiceOperationId] = @ServiceOperationId
          AND (@Name IS NULL OR f.[Name] = @Name)
          AND (
                @IncludePreviousVersions = 1
                OR f.[Id] IN (
                    SELECT ServiceRequestFileId
                    FROM [dbo].[vw_ServiceRequestFileLatest]
                    WHERE ServiceOperationId = @ServiceOperationId
                )
              )
        ORDER BY l.[ServiceRequestFileId], l.[Id];
    END
END;
GO
