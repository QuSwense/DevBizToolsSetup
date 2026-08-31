/*
    View: v_ActiveServiceOperations
    Description: Active operations only for dropdowns and lookups.
*/
CREATE VIEW [dbo].[v_ActiveServiceOperations]
AS
SELECT 
    so.[Id] AS OperationId,
    so.[OperationName],
    so.[EndpointOrAction],
    so.[HttpMethod],
    so.[Description],
    sa.[PublicId] AS ServicePublicId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    CONCAT(sa.[Name], ' - ', so.[OperationName]) AS DisplayName
FROM [dbo].[ServiceOperations] so
INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
WHERE so.[IsActive] = 1
  AND sa.[IsActive] = 1;
GO