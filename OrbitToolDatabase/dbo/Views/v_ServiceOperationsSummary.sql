/*
    View: v_ServiceOperationsSummary
    Description: Summary of operations per service application.
*/
CREATE VIEW [dbo].[v_ServiceOperationsSummary]
AS
SELECT 
    sa.[PublicId] AS ServicePublicId,
    sa.[Id] AS ServiceInternalId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[IsActive] AS ServiceIsActive,
    
    -- Operation Counts
    COUNT(DISTINCT so.[Id]) AS TotalOperations,
    COUNT(DISTINCT CASE WHEN so.[IsActive] = 1 THEN so.[Id] END) AS ActiveOperations,
    COUNT(DISTINCT CASE WHEN so.[IsActive] = 0 THEN so.[Id] END) AS InactiveOperations,
    
    -- Operations with schemas (via a pre-joined derived table, since an EXISTS
    -- subquery cannot be nested inside an aggregate in a grouped view)
    COUNT(DISTINCT CASE WHEN sos.[ServiceOperationId] IS NOT NULL THEN so.[Id] END) AS OperationsWithSchemas,
    
    -- HTTP Method Distribution (using FOR XML PATH for compatibility)
    STUFF((
        SELECT DISTINCT ', ' + so2.[HttpMethod]
        FROM [dbo].[ServiceOperations] so2
        WHERE so2.[ServiceApplicationId] = sa.[Id]
          AND so2.[HttpMethod] IS NOT NULL
        FOR XML PATH('')
    ), 1, 2, '') AS HttpMethodsUsed,
    
    -- Operation Names List (active only)
    STUFF((
        SELECT ', ' + so2.[OperationName]
        FROM [dbo].[ServiceOperations] so2
        WHERE so2.[ServiceApplicationId] = sa.[Id]
          AND so2.[IsActive] = 1
        ORDER BY so2.[OperationName]
        FOR XML PATH('')
    ), 1, 2, '') AS ActiveOperationNames,
    
    -- Operation Names List (all operations)
    STUFF((
        SELECT ', ' + so2.[OperationName]
        FROM [dbo].[ServiceOperations] so2
        WHERE so2.[ServiceApplicationId] = sa.[Id]
        ORDER BY so2.[OperationName]
        FOR XML PATH('')
    ), 1, 2, '') AS AllOperationNames,
    
    -- Last Operation Update
    MAX(so.[LastUpdatedAt]) AS LastOperationUpdate,
    MAX(so.[LastUpdatedBy]) AS LastOperationUpdater,
    
    -- Creation Info
    MIN(so.[CreatedAt]) AS FirstOperationCreated,
    MAX(so.[CreatedAt]) AS LatestOperationCreated,
    
    -- Additional metadata
    COUNT(DISTINCT CASE WHEN so.[HttpMethod] = 'GET' THEN so.[Id] END) AS GetOperations,
    COUNT(DISTINCT CASE WHEN so.[HttpMethod] = 'POST' THEN so.[Id] END) AS PostOperations,
    COUNT(DISTINCT CASE WHEN so.[HttpMethod] = 'PUT' THEN so.[Id] END) AS PutOperations,
    COUNT(DISTINCT CASE WHEN so.[HttpMethod] = 'DELETE' THEN so.[Id] END) AS DeleteOperations,
    COUNT(DISTINCT CASE WHEN so.[HttpMethod] IS NULL THEN so.[Id] END) AS NoHttpMethodOperations

FROM [dbo].[ServiceApplications] sa
LEFT JOIN [dbo].[ServiceOperations] so ON sa.[Id] = so.[ServiceApplicationId]
LEFT JOIN (
    SELECT DISTINCT [ServiceOperationId]
    FROM [dbo].[ServiceOperationSchemas]
) sos ON sos.[ServiceOperationId] = so.[Id]
GROUP BY sa.[PublicId], sa.[Id], sa.[Name], sa.[ServiceType], sa.[BaseUrl], sa.[IsActive];
GO