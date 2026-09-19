/*
    View: vw_ServiceRequestFileLatest
    Latest version of each request file per (ServiceOperationId, Name).
*/
CREATE OR ALTER VIEW [dbo].[vw_ServiceRequestFileLatest]
AS
SELECT
    f.[Id]                      AS ServiceRequestFileId,
    f.[PublicId],
    f.[ServiceOperationId],
    f.[FileFormat],
    f.[Name],
    f.[UncompressedSizeBytes],
    f.[CompressionAlgorithmType],
    f.[RecordVersion],
    f.[IsActive],
    f.[CreatedAt],
    f.[CreatedBy]
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY [ServiceOperationId], [Name]
            ORDER BY [Id] DESC
        ) AS rn
    FROM [dbo].[ServiceRequestFiles]
) f
WHERE f.rn = 1;
GO
