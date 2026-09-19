/*
    View: vw_ServiceApplicationLatestDefinition
    Latest definition per ServiceApplicationId.
*/
CREATE OR ALTER VIEW [dbo].[vw_ServiceApplicationLatestDefinition]
AS
SELECT
    s.[Id]                      AS ServiceDefinitionSyncId,
    s.[ServiceApplicationId],
    s.[DefinitionUrl],
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
            PARTITION BY [ServiceApplicationId]
            ORDER BY [Id] DESC
        ) AS rn
    FROM [dbo].[ServiceDefinitionSyncs]
) s
WHERE s.rn = 1;
GO
