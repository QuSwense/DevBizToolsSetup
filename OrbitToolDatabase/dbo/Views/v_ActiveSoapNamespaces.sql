/*
    View: v_ActiveSoapNamespaces
    Description: Active SOAP namespaces for dropdowns and lookups.
*/
CREATE VIEW [dbo].[v_ActiveSoapNamespaces]
AS
SELECT 
    sn.[Id] AS NamespaceId,
    so.[OperationName],
    sa.[Name] AS ServiceName,
    sa.[PublicId] AS ServicePublicId,
    sn.[ContentHash],
    sn.[UncompressedSizeBytes],
    sn.[CompressionAlgorithmType],
    sn.[CreatedAt],
    CONCAT(sa.[Name], ' - ', so.[OperationName]) AS DisplayName,
    CONCAT(LEFT(sn.[ContentHash], 16), '...') AS HashShort
FROM [dbo].[SoapNamespaces] sn
INNER JOIN [dbo].[ServiceOperationSchemas] sos ON sn.[ServiceOperationSchemaId] = sos.[Id]
INNER JOIN [dbo].[ServiceOperations] so ON sos.[ServiceOperationId] = so.[Id]
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
WHERE so.[IsActive] = 1
  AND sa.[IsActive] = 1;
GO