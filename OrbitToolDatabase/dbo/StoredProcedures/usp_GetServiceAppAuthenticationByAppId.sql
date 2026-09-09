/*
    Stored Procedure: usp_GetServiceAppAuthenticationByAppId
    Description: Gets the active authentication configuration for a specific application by its int Id.
*/
CREATE PROCEDURE [dbo].[usp_GetServiceAppAuthenticationByAppId]
    @ServiceApplicationId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuthId BIGINT;

    -- Get the ServiceAppAuthenticationId from the application
    SELECT @AuthId = [ServiceAppAuthenticationId]
    FROM [dbo].[ServiceApplications]
    WHERE [Id] = @ServiceApplicationId;

    -- Return the authentication record if it exists and is active
    IF @AuthId IS NOT NULL
    BEGIN
        SELECT
            [Id],
            [PublicId],
            [Name],
            [AuthenticationType],
            [EncryptionAlgorithmType],
            [EncryptedJson],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        FROM [dbo].[ServiceAppAuthentications]
        WHERE [Id] = @AuthId
          AND [IsActive] = 1;
    END
END;
GO