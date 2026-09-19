/*
    View: vw_ServiceRequestFileWithLinks
    Joins every ServiceRequestFile to its embedding-store links.
    Useful for UI lists that need both file metadata and link summary.
*/
CREATE OR ALTER VIEW [dbo].[vw_ServiceRequestFileWithLinks]
AS
SELECT
    f.[Id]                          AS ServiceRequestFileId,
    f.[PublicId]                    AS FilePublicId,
    f.[ServiceOperationId],
    f.[FileFormat],
    f.[Name]                        AS FileName,
    f.[UncompressedSizeBytes],
    f.[CompressionAlgorithmType],
    f.[RecordVersion],
    f.[IsActive],
    f.[CreatedAt]                   AS FileCreatedAt,
    f.[CreatedBy]                   AS FileCreatedBy,

    l.[Id]                          AS LinkId,
    l.[PublicId]                    AS LinkPublicId,
    l.[ElementName],
    l.[XmlPath],
    l.[BinaryEmbeddingsStoreId],
    l.[Name]                        AS LinkName,
    l.[AdditionalDetails],
    l.[CreatedAt]                   AS LinkCreatedAt,
    l.[CreatedBy]                   AS LinkCreatedBy
FROM [dbo].[ServiceRequestFiles] f
LEFT JOIN [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks] l
    ON l.[ServiceRequestFileId] = f.[Id];
GO
