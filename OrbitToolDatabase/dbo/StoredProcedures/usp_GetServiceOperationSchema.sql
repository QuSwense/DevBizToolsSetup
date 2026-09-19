/*
    Stored Procedure: usp_GetServiceOperationSchema

    Retrieves schema(s) for an operation version.
    @IncludePreviousVersions = 0 → latest schema only
    @IncludePreviousVersions = 1 → full schema history
    @IncludeContent          = 0 → metadata only
    @IncludeContent          = 1 → include CompressedContent
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceOperationSchema]
    @ServiceOperationId         INT = NULL,
    @ServiceOperationSchemaId   INT = NULL,
    @IncludePreviousVersions    BIT = 0,
    @IncludeContent             BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @ServiceOperationId IS NULL
       AND @ServiceOperationSchemaId IS NULL
        RAISERROR('Provide ServiceOperationId or ServiceOperationSchemaId.', 16, 1);

    ;WITH Matched AS
    (
        SELECT
            s.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY s.[ServiceOperationId]
                ORDER BY s.[Id] DESC
            ) AS rn
        FROM [dbo].[ServiceOperationSchemas] s
        WHERE (@ServiceOperationId IS NULL OR s.[ServiceOperationId] = @ServiceOperationId)
          AND (@ServiceOperationSchemaId IS NULL OR s.[Id] = @ServiceOperationSchemaId)
    )
    SELECT
        [Id]                        AS ServiceOperationSchemaId,
        [ServiceOperationId],
        [InputRootElementName],
        [OutputRootElementName],
        [TargetNamespace],
        CASE WHEN @IncludeContent = 1 THEN [CompressedContent] END AS CompressedContent,
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        CASE WHEN rn = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsLatest
    FROM Matched
    WHERE @IncludePreviousVersions = 1 OR rn = 1
    ORDER BY [Id] DESC;
END;
GO
