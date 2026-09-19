/*
    Stored Procedure: usp_GetServiceOperation

    Lookup by either:
      - ServiceOperationId, or
      - ServiceApplicationId + OperationName

    @IncludePreviousVersions = 1 returns the full history of the logical operation.
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceOperation]
    @ServiceOperationId         INT = NULL,
    @ServiceApplicationId       INT = NULL,
    @OperationName              NVARCHAR(200) = NULL,
    @IncludePreviousVersions    BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @ServiceOperationId IS NULL
       AND (@ServiceApplicationId IS NULL OR @OperationName IS NULL)
        RAISERROR('Provide ServiceOperationId, or ServiceApplicationId + OperationName.', 16, 1);

    ;WITH Matched AS
    (
        SELECT
            o.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY o.[ServiceApplicationId], o.[OperationName]
                ORDER BY o.[Id] DESC
            ) AS rn
        FROM [dbo].[ServiceOperations] o
        WHERE (@ServiceOperationId IS NULL OR o.[Id] = @ServiceOperationId)
          AND (@ServiceApplicationId IS NULL OR o.[ServiceApplicationId] = @ServiceApplicationId)
          AND (@OperationName IS NULL OR o.[OperationName] = @OperationName)
    )
    SELECT
        [Id]                        AS ServiceOperationId,
        [ServiceApplicationId],
        [ServiceDefinitionSyncId],
        [OperationName],
        [EndpointOrAction],
        [HttpMethod],
        [Description],
        [IsActive],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        CASE WHEN rn = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsLatest
    FROM Matched
    WHERE @IncludePreviousVersions = 1 OR rn = 1
    ORDER BY [Id] DESC;
END;
GO
