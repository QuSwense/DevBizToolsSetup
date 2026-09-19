/*
    Stored Procedure: usp_SaveServiceOperationSchema

    Logical identity: ServiceOperationId (concrete operation version)
    Always creates a new immutable schema version for that operation version.

    The application should pass the ServiceOperationId returned by
    usp_SaveServiceOperation.
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveServiceOperationSchema]
    @ServiceOperationId         INT,
    @InputRootElementName       NVARCHAR(200) = NULL,
    @OutputRootElementName      NVARCHAR(200) = NULL,
    @TargetNamespace            NVARCHAR(500) = NULL,
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

        IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceOperations] WHERE [Id] = @ServiceOperationId)
            RAISERROR('Service operation was not found.', 16, 1);

        IF @CompressedContent IS NULL
            RAISERROR('Compressed schema content is required.', 16, 1);

        IF @CompressionAlgorithmType IS NOT NULL
           AND @CompressionAlgorithmType NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
            RAISERROR('Invalid CompressionAlgorithmType.', 16, 1);

        INSERT INTO [dbo].[ServiceOperationSchemas]
        (
            [ServiceOperationId],
            [InputRootElementName],
            [OutputRootElementName],
            [TargetNamespace],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES
        (
            @ServiceOperationId,
            @InputRootElementName,
            @OutputRootElementName,
            @TargetNamespace,
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
            @NewId                      AS ServiceOperationSchemaId,
            [ServiceOperationId],
            [InputRootElementName],
            [OutputRootElementName],
            [TargetNamespace],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            CAST(1 AS BIT)              AS WasCreated,
            'Created'                   AS SaveResult
        FROM [dbo].[ServiceOperationSchemas]
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
