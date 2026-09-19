/*
    View: vw_ServiceOperationLatestSchema
    Latest schema version per ServiceOperationId.
*/
CREATE OR ALTER VIEW [dbo].[vw_ServiceOperationLatestSchema]
AS
SELECT
    s.[Id]                      AS ServiceOperationSchemaId,
    s.[ServiceOperationId],
    s.[InputRootElementName],
    s.[OutputRootElementName],
    s.[TargetNamespace],
    s.[UncompressedSizeBytes],
    s.[CompressionAlgorithmType],
    s.[RecordVersion],
    s.[CreatedAt],
    s.[CreatedBy]
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY [ServiceOperationId]
            ORDER BY [Id] DESC
        ) AS rn
    FROM [dbo].[ServiceOperationSchemas]
) s
WHERE s.rn = 1;
GO
