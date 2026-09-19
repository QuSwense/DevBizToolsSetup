/*
    Stored Procedure: usp_GetServiceOperations

    Returns operations for one application.
    @IncludePreviousVersions = 0 → latest version of each logical operation
    @IncludePreviousVersions = 1 → complete history
    @OperationName (optional) → filter to a single operation
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceOperations]
    @ServiceApplicationId       INT,
    @IncludePreviousVersions    BIT = 0,
    @OperationName              NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceApplications] WHERE [Id] = @ServiceApplicationId)
        RAISERROR('Service application was not found.', 16, 1);

    ;WITH Ranked AS
    (
        SELECT
            o.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY o.[ServiceApplicationId], o.[OperationName]
                ORDER BY o.[Id] DESC
            ) AS rn
        FROM [dbo].[ServiceOperations] o
        WHERE o.[ServiceApplicationId] = @ServiceApplicationId
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
    FROM Ranked
    WHERE @IncludePreviousVersions = 1 OR rn = 1
    ORDER BY [OperationName], [Id] DESC;
END;
GO
