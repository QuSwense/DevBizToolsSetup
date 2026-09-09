/*
    Stored Procedure: usp_GetServiceDefinitionSyncLatestVersion
    Description: Gets the latest RecordVersion from definition syncs for an application.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceDefinitionSyncLatestVersion]
    @ServiceApplicationId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        [RecordVersion]
    FROM [dbo].[ServiceDefinitionSyncs]
    WHERE [ServiceApplicationId] = @ServiceApplicationId
    ORDER BY [CreatedAt] DESC;
END;
GO