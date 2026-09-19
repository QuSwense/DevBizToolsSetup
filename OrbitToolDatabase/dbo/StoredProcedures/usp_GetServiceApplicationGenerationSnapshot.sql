/*
    Stored Procedure: usp_GetServiceApplicationGenerationSnapshot

    One call for the generation / review UI.
    Returns three result sets (metadata only – no large blobs):
      1. Latest definition
      2. Latest operations
      3. Latest schemas (joined to the application's operations)
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetServiceApplicationGenerationSnapshot]
    @ServiceApplicationId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceApplications] WHERE [Id] = @ServiceApplicationId)
        RAISERROR('Service application was not found.', 16, 1);

    -- 1. Latest definition
    SELECT
        ServiceDefinitionSyncId,
        ServiceApplicationId,
        DefinitionUrl,
        UncompressedSizeBytes,
        CompressionAlgorithmType,
        RecordVersion,
        CreatedAt,
        CreatedBy
    FROM [dbo].[vw_ServiceApplicationLatestDefinition]
    WHERE ServiceApplicationId = @ServiceApplicationId;

    -- 2. Latest operations
    SELECT
        ServiceOperationId,
        ServiceApplicationId,
        ServiceDefinitionSyncId,
        OperationName,
        EndpointOrAction,
        HttpMethod,
        Description,
        IsActive,
        RecordVersion,
        CreatedAt,
        CreatedBy
    FROM [dbo].[vw_ServiceApplicationLatestOperations]
    WHERE ServiceApplicationId = @ServiceApplicationId
    ORDER BY OperationName;

    -- 3. Latest schemas for those operations
    SELECT
        s.ServiceOperationSchemaId,
        s.ServiceOperationId,
        s.InputRootElementName,
        s.OutputRootElementName,
        s.TargetNamespace,
        s.UncompressedSizeBytes,
        s.CompressionAlgorithmType,
        s.RecordVersion,
        s.CreatedAt,
        s.CreatedBy
    FROM [dbo].[vw_ServiceOperationLatestSchema] s
    INNER JOIN [dbo].[ServiceOperations] o
        ON o.Id = s.ServiceOperationId
    WHERE o.ServiceApplicationId = @ServiceApplicationId
    ORDER BY o.OperationName;
END;
GO
