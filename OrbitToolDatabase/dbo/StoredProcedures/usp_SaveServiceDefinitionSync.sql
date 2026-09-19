/*
    Stored Procedure: usp_SaveServiceDefinitionSync

    Always creates a new immutable version of the service definition
    for the given ServiceApplicationId.

    Designed for the single-click sync flow:
      1. .NET fetches + compresses the definition (WSDL / OpenAPI / Swagger)
      2. Calls this procedure
      3. Receives the new ServiceDefinitionSyncId to link subsequent operations
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveServiceDefinitionSync]
    @ServiceApplicationId       INT,
    @DefinitionUrl              NVARCHAR(1024) = NULL,
    @CompressedContent          VARBINARY(MAX),
    @UncompressedSizeBytes      BIGINT = NULL,
    @CompressionAlgorithmType   VARCHAR(50) = NULL,
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

        IF @CompressedContent IS NULL
            RAISERROR('Compressed content is required.', 16, 1);

        IF @CompressionAlgorithmType IS NOT NULL
           AND @CompressionAlgorithmType NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
            RAISERROR('Invalid CompressionAlgorithmType.', 16, 1);

        INSERT INTO [dbo].[ServiceDefinitionSyncs]
        (
            [ServiceApplicationId],
            [DefinitionUrl],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES
        (
            @ServiceApplicationId,
            @DefinitionUrl,
            @CompressedContent,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            GETDATE(),
            @ResolvedUser
        );

        SET @NewId = CONVERT(INT, SCOPE_IDENTITY());

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            @NewId                      AS ServiceDefinitionSyncId,
            [ServiceApplicationId],
            [DefinitionUrl],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            CAST(1 AS BIT)              AS WasCreated,
            'Created'                   AS SaveResult
        FROM [dbo].[ServiceDefinitionSyncs]
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
