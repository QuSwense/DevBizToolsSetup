/*
    Stored Procedure: usp_GetServiceDefinitions

    @IncludePreviousVersions = 0 → latest definition only
    @IncludePreviousVersions = 1 → full history
    @IncludeContent          = 0 → metadata only
    @IncludeContent          = 1 → include CompressedContent
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceDefinitions]
    @ServiceApplicationId       INT,
    @IncludePreviousVersions    BIT = 0,
    @IncludeContent             BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceApplications] WHERE [Id] = @ServiceApplicationId)
        RAISERROR('Service application was not found.', 16, 1);

    ;WITH Ranked AS
    (
        SELECT
            s.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY s.[ServiceApplicationId]
                ORDER BY s.[Id] DESC
            ) AS rn
        FROM [dbo].[ServiceDefinitionSyncs] s
        WHERE s.[ServiceApplicationId] = @ServiceApplicationId
    )
    SELECT
        [Id]                        AS ServiceDefinitionSyncId,
        [ServiceApplicationId],
        [DefinitionUrl],
        CASE WHEN @IncludeContent = 1 THEN [CompressedContent] END AS CompressedContent,
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        CASE WHEN rn = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsLatest
    FROM Ranked
    WHERE @IncludePreviousVersions = 1 OR rn = 1
    ORDER BY [Id] DESC;
END;
GO
