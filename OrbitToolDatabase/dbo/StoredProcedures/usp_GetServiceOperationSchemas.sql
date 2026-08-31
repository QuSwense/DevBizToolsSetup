/*
    Stored Procedure: usp_GetServiceOperationSchemas
    Description: Gets schemas for a service operation.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceOperationSchemas]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @OperationName NVARCHAR(200) = NULL,
    @IncludeContent BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ServiceAppId INT;

    -- Get the service application internal ID
    SELECT TOP 1 @ServiceAppId = [Id]
    FROM [dbo].[ServiceApplications]
    WHERE [PublicId] = @ServiceApplicationPublicId
    ORDER BY [Id] DESC;

    IF @ServiceAppId IS NULL
    BEGIN
        RAISERROR('Service application not found.', 16, 1);
        RETURN;
    END

    IF @IncludeContent = 1
    BEGIN
        SELECT 
            sos.[Id] AS SchemaId,
            sos.[ServiceDefinitionSyncId],
            sos.[ServiceOperationId],
            so.[OperationName],
            sos.[InputRootElementName],
            sos.[OutputRootElementName],
            sos.[TargetNamespace],
            sos.[CompressedContent],  -- Include content
            sos.[UncompressedSizeBytes],
            sos.[CompressionAlgorithmType],
            sos.[ContentHash],
            sos.[RecordVersion],
            sos.[CreatedAt],
            sos.[CreatedBy],
            sos.[LastUpdatedAt],
            sos.[LastUpdatedBy]
        FROM [dbo].[ServiceOperationSchemas] sos
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        WHERE so.[ServiceApplicationId] = @ServiceAppId
          AND so.[IsActive] = 1
          AND (@OperationName IS NULL OR so.[OperationName] = @OperationName)
        ORDER BY so.[OperationName];
    END
    ELSE
    BEGIN
        SELECT 
            sos.[Id] AS SchemaId,
            sos.[ServiceDefinitionSyncId],
            sos.[ServiceOperationId],
            so.[OperationName],
            sos.[InputRootElementName],
            sos.[OutputRootElementName],
            sos.[TargetNamespace],
            CAST(0x AS VARBINARY(1)) AS CompressedContent,  -- Placeholder
            sos.[UncompressedSizeBytes],
            sos.[CompressionAlgorithmType],
            sos.[ContentHash],
            sos.[RecordVersion],
            sos.[CreatedAt],
            sos.[CreatedBy],
            sos.[LastUpdatedAt],
            sos.[LastUpdatedBy]
        FROM [dbo].[ServiceOperationSchemas] sos
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        WHERE so.[ServiceApplicationId] = @ServiceAppId
          AND so.[IsActive] = 1
          AND (@OperationName IS NULL OR so.[OperationName] = @OperationName)
        ORDER BY so.[OperationName];
    END
END;
GO