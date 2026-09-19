/*
    Stored Procedure: usp_SaveServiceOperation

    Logical identity: ServiceApplicationId + OperationName
    Always creates a new immutable version.

    ServiceDefinitionSyncId is optional source metadata only
    (does not affect logical identity or uniqueness).
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveServiceOperation]
    @ServiceApplicationId       INT,
    @ServiceDefinitionSyncId    INT = NULL,
    @OperationName              NVARCHAR(200),
    @EndpointOrAction           NVARCHAR(500) = NULL,
    @HttpMethod                 VARCHAR(10) = NULL,
    @Description                NVARCHAR(MAX) = NULL,
    @IsActive                   BIT = 1,
    @UserId                     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LocalTranStarted BIT = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE
            @ResolvedUser   NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM'),
            @NewId          INT;

        IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceApplications] WHERE [Id] = @ServiceApplicationId)
            RAISERROR('Service application was not found.', 16, 1);

        IF @ServiceDefinitionSyncId IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM [dbo].[ServiceDefinitionSyncs]
               WHERE [Id] = @ServiceDefinitionSyncId
                 AND [ServiceApplicationId] = @ServiceApplicationId
           )
            RAISERROR('Service definition sync does not belong to the service application.', 16, 1);

        IF NULLIF(LTRIM(RTRIM(@OperationName)), '') IS NULL
            RAISERROR('OperationName is required.', 16, 1);

        IF @HttpMethod IS NOT NULL
           AND @HttpMethod NOT IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
            RAISERROR('Invalid HttpMethod.', 16, 1);

        INSERT INTO [dbo].[ServiceOperations]
        (
            [ServiceApplicationId],
            [ServiceDefinitionSyncId],
            [OperationName],
            [EndpointOrAction],
            [HttpMethod],
            [Description],
            [IsActive],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES
        (
            @ServiceApplicationId,
            @ServiceDefinitionSyncId,
            @OperationName,
            @EndpointOrAction,
            @HttpMethod,
            @Description,
            @IsActive,
            GETDATE(),
            @ResolvedUser
        );

        SET @NewId = CONVERT(INT, SCOPE_IDENTITY());

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            @NewId                      AS ServiceOperationId,
            [ServiceApplicationId],
            [ServiceDefinitionSyncId],
            [OperationName],
            [EndpointOrAction],
            [HttpMethod],
            [Description],
            [IsActive],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            CAST(1 AS BIT)              AS WasCreated,
            'Created'                   AS SaveResult
        FROM [dbo].[ServiceOperations]
        WHERE [Id] = @NewId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR('%s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
