/*
    Stored Procedure: usp_GetServiceRequestFileConsecutiveDeltaCount
    Description: Gets the count of consecutive delta records since the most recent base snapshot
    for a given request file.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceRequestFileConsecutiveDeltaCount]
    @RequestFileId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BaseId INT;

    -- Find the base snapshot ID for this delta chain
    SELECT @BaseId = COALESCE([ParentBaseId], [Id])
    FROM [dbo].[ServiceRequestFiles]
    WHERE [Id] = @RequestFileId;

    -- Count all non-base records in this delta chain
    SELECT COUNT(*) AS DeltaCount
    FROM [dbo].[ServiceRequestFiles]
    WHERE [ParentBaseId] = @BaseId
      AND [IsBaseSnapshot] = 0;
END;
GO