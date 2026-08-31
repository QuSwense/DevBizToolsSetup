/*
    Stored Procedure: usp_GetSoapNamespacesByService
    Description: Gets all SOAP namespaces for a service application.
*/
CREATE PROCEDURE [dbo].[usp_GetSoapNamespacesByService]
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
            sn.[Id] AS NamespaceId,
            sn.[ServiceOperationSchemaId],
            sn.[CompressedContent],
            sn.[UncompressedSizeBytes],
            sn.[CompressionAlgorithmType],
            sn.[ContentHash],
            sn.[RecordVersion],
            sn.[CreatedAt],
            sn.[CreatedBy],
            sn.[LastUpdatedAt],
            sn.[LastUpdatedBy],
            so.[OperationName],
            so.[Id] AS OperationId,
            sa.[Name] AS ServiceName,
            sa.[PublicId] AS ServicePublicId
        FROM [dbo].[SoapNamespaces] sn
        INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE sa.[Id] = @ServiceAppId
          AND (@OperationName IS NULL OR so.[OperationName] = @OperationName)
          AND so.[IsActive] = 1
        ORDER BY so.[OperationName], sn.[CreatedAt] DESC;
    END
    ELSE
    BEGIN
        SELECT 
            sn.[Id] AS NamespaceId,
            sn.[ServiceOperationSchemaId],
            CAST(0x AS VARBINARY(1)) AS CompressedContent,  -- Placeholder
            sn.[UncompressedSizeBytes],
            sn.[CompressionAlgorithmType],
            sn.[ContentHash],
            sn.[RecordVersion],
            sn.[CreatedAt],
            sn.[CreatedBy],
            sn.[LastUpdatedAt],
            sn.[LastUpdatedBy],
            so.[OperationName],
            so.[Id] AS OperationId,
            sa.[Name] AS ServiceName,
            sa.[PublicId] AS ServicePublicId
        FROM [dbo].[SoapNamespaces] sn
        INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
        INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE sa.[Id] = @ServiceAppId
          AND (@OperationName IS NULL OR so.[OperationName] = @OperationName)
          AND so.[IsActive] = 1
        ORDER BY so.[OperationName], sn.[CreatedAt] DESC;
    END
END;
GO