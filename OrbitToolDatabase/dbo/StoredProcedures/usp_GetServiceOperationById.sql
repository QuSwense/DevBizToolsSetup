/*
    Stored Procedure: usp_GetServiceOperationById
    Description: Gets a service operation by its primary key identifier (int Id).
*/
CREATE PROCEDURE [dbo].[usp_GetServiceOperationById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id],
        [ServiceApplicationId],
        [OperationName],
        [EndpointOrAction],
        [HttpMethod],
        [Description],
        [IsActive],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy]
    FROM [dbo].[ServiceOperations]
    WHERE [Id] = @Id;
END;
GO