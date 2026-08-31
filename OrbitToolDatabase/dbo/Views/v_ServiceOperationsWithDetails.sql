/*
    View: v_ServiceOperationsWithDetails
    Description: Comprehensive view of service operations with service details.
*/
CREATE VIEW [dbo].[v_ServiceOperationsWithDetails]
AS
SELECT 
    so.[Id] AS OperationId,
    so.[ServiceApplicationId],
    so.[OperationName],
    so.[EndpointOrAction],
    so.[HttpMethod],
    so.[Description],
    so.[IsActive],
    so.[RecordVersion] AS OperationRecordVersion,
    so.[CreatedAt] AS OperationCreatedAt,
    so.[CreatedBy] AS OperationCreatedBy,
    so.[LastUpdatedAt] AS OperationLastUpdatedAt,
    so.[LastUpdatedBy] AS OperationLastUpdatedBy,
    
    -- Service Details
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[DefinitionType],
    sa.[DefinitionRelativeUrl],
    sa.[IsActive] AS ServiceIsActive,
    sa.[RecordVersion] AS ServiceRecordVersion,
    
    -- Schema Status
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceOperationSchemas] sos
            WHERE sos.[ServiceOperationId] = so.[Id]
        ) THEN 1
        ELSE 0
    END AS HasSchema,
    (
        SELECT COUNT(*)
        FROM [dbo].[ServiceOperationSchemas] sos
        WHERE sos.[ServiceOperationId] = so.[Id]
    ) AS SchemaCount,
    
    -- Status Description
    CASE 
        WHEN so.[IsActive] = 1 AND EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceOperationSchemas] sos
            WHERE sos.[ServiceOperationId] = so.[Id]
        ) THEN 'Active with Schema'
        WHEN so.[IsActive] = 1 AND NOT EXISTS (
            SELECT 1 
            FROM [dbo].[ServiceOperationSchemas] sos
            WHERE sos.[ServiceOperationId] = so.[Id]
        ) THEN 'Active - No Schema'
        ELSE 'Inactive'
    END AS OperationStatus,
    
    -- Derived fields
    CASE 
        WHEN so.[HttpMethod] IS NOT NULL THEN 
            CONCAT(so.[OperationName], ' (', so.[HttpMethod], ')')
        ELSE 
            so.[OperationName]
    END AS DisplayName,
    
    DATEDIFF(DAY, so.[CreatedAt], GETDATE()) AS DaysSinceCreation,
    DATEDIFF(DAY, so.[LastUpdatedAt], GETDATE()) AS DaysSinceLastUpdate

FROM [dbo].[ServiceOperations] so
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id];
GO