/*
    Stored Procedure: usp_GetServiceOperations
    Description: Gets all operations for a service application.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceOperations]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @IncludeInactive BIT = 0,
    @OperationName NVARCHAR(200) = NULL
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

    SELECT 
        so.[Id] AS OperationId,
        so.[ServiceApplicationId],
        so.[OperationName],
        so.[EndpointOrAction],
        so.[HttpMethod],
        so.[Description],
        so.[IsActive],
        so.[RecordVersion],
        so.[CreatedAt],
        so.[CreatedBy],
        so.[LastUpdatedAt],
        so.[LastUpdatedBy],
        -- Count of schemas for this operation
        (
            SELECT COUNT(*)
            FROM [dbo].[ServiceOperationSchemas] sos
            WHERE sos.[ServiceOperationId] = so.[Id]
        ) AS SchemaCount,
        -- Check if schema exists
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [dbo].[ServiceOperationSchemas] sos
                WHERE sos.[ServiceOperationId] = so.[Id]
            ) THEN 1
            ELSE 0
        END AS HasSchema
    FROM [dbo].[ServiceOperations] so
    WHERE so.[ServiceApplicationId] = @ServiceAppId
      AND (@IncludeInactive = 1 OR so.[IsActive] = 1)
      AND (@OperationName IS NULL OR so.[OperationName] = @OperationName)
    ORDER BY so.[OperationName];
END;
GO