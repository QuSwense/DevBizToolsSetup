/*
    View: vw_ServiceApplicationLatestOperations
    Latest operation version per (ServiceApplicationId, OperationName).
*/
CREATE OR ALTER VIEW [dbo].[vw_ServiceApplicationLatestOperations]
AS
SELECT
    o.[Id]                      AS ServiceOperationId,
    o.[ServiceApplicationId],
    o.[ServiceDefinitionSyncId],
    o.[OperationName],
    o.[EndpointOrAction],
    o.[HttpMethod],
    o.[Description],
    o.[IsActive],
    o.[RecordVersion],
    o.[CreatedAt],
    o.[CreatedBy]
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY [ServiceApplicationId], [OperationName]
            ORDER BY [Id] DESC
        ) AS rn
    FROM [dbo].[ServiceOperations]
) o
WHERE o.rn = 1;
GO
