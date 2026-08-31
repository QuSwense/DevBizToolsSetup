/*
    Stored Procedure: usp_GetSoapNamespaces
    Description: Gets SOAP namespaces for a service operation schema.
*/
CREATE PROCEDURE [dbo].[usp_GetSoapNamespaces]
    @ServiceOperationSchemaId INT = NULL,
    @NamespaceId INT = NULL,
    @IncludeContent BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @NamespaceId IS NOT NULL
    BEGIN
        -- Get specific namespace
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
                sa.[Name] AS ServiceName,
                sa.[PublicId] AS ServicePublicId
            FROM [dbo].[SoapNamespaces] sn
            INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
            INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
            INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
            WHERE sn.[Id] = @NamespaceId;
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
                sa.[Name] AS ServiceName,
                sa.[PublicId] AS ServicePublicId
            FROM [dbo].[SoapNamespaces] sn
            INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
            INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
            INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
            WHERE sn.[Id] = @NamespaceId;
        END
    END
    ELSE IF @ServiceOperationSchemaId IS NOT NULL
    BEGIN
        -- Get all namespaces for a schema
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
                sa.[Name] AS ServiceName,
                sa.[PublicId] AS ServicePublicId
            FROM [dbo].[SoapNamespaces] sn
            INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
            INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
            INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
            WHERE sn.[ServiceOperationSchemaId] = @ServiceOperationSchemaId
            ORDER BY sn.[CreatedAt] DESC;
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
                sa.[Name] AS ServiceName,
                sa.[PublicId] AS ServicePublicId
            FROM [dbo].[SoapNamespaces] sn
            INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
            INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
            INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
            WHERE sn.[ServiceOperationSchemaId] = @ServiceOperationSchemaId
            ORDER BY sn.[CreatedAt] DESC;
        END
    END
    ELSE
    BEGIN
        RAISERROR('Either ServiceOperationSchemaId or NamespaceId must be provided.', 16, 1);
        RETURN;
    END
END;
GO