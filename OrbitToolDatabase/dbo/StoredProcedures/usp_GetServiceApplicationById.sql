/*
    Stored Procedure: usp_GetServiceApplicationById
    Description: Gets a service application by its primary key identifier (int Id).
    Returns all fields including the PublicId for use in other SP calls.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceApplicationById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Id],
        [PublicId],
        [ServiceType],
        [ServiceAppAuthenticationId],
        [Name],
        [BaseUrl],
        [DefinitionType],
        [DefinitionRelativeUrl],
        [HealthcheckRelativeUrl],
        [Description],
        [IsActive],
        [RecordVersion],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy]
    FROM [dbo].[ServiceApplications]
    WHERE [Id] = @Id;
END;
GO