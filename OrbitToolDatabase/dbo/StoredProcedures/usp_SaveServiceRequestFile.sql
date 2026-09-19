/*
    Stored Procedure: usp_SaveServiceRequestFile

    Single SP that creates:
      1. One row in ServiceRequestFiles
      2. Zero or more rows in ServiceRequestFileBinaryEmbeddingStoreLinks

    The caller is responsible for first inserting / resolving rows in
    BinaryEmbeddingStores (content-addressable) and supplying the resulting
    BinaryEmbeddingsStoreId values via the TVP.

    Always inserts a new immutable version of the file
    (unique on ServiceOperationId + Name + RecordVersion).

    Result sets
    -----------
    1. The newly created ServiceRequestFile row
    2. The newly created link rows (if any)
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_SaveServiceRequestFile]
    @ServiceOperationId         INT,
    @FileFormat                 VARCHAR(10) = NULL,
    @Name                       NVARCHAR(250),
    @CompressedData             VARBINARY(MAX),
    @UncompressedSizeBytes      BIGINT = NULL,
    @CompressionAlgorithmType   VARCHAR(50) = NULL,
    @IsActive                   BIT = 1,
    @EmbeddingLinks             [dbo].[ServiceRequestFileEmbeddingLinkInput] READONLY,
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
            @NewFileId      INT,
            @NewPublicId    UNIQUEIDENTIFIER = NEWID();

        /* ---------- Validation ---------- */
        IF NOT EXISTS (SELECT 1 FROM [dbo].[ServiceOperations] WHERE [Id] = @ServiceOperationId)
            RAISERROR('Service operation was not found.', 16, 1);

        IF NULLIF(LTRIM(RTRIM(@Name)), '') IS NULL
            RAISERROR('File Name is required.', 16, 1);

        IF @CompressedData IS NULL
            RAISERROR('CompressedData is required.', 16, 1);

        IF @FileFormat IS NOT NULL
           AND @FileFormat NOT IN ('XML', 'JSON')
            RAISERROR('Invalid FileFormat. Allowed values: XML, JSON.', 16, 1);

        IF @CompressionAlgorithmType IS NOT NULL
           AND @CompressionAlgorithmType NOT IN ('Zstandard', 'Brotli', 'Gzip', 'none')
            RAISERROR('Invalid CompressionAlgorithmType.', 16, 1);

        -- Validate that every BinaryEmbeddingsStoreId exists
        IF EXISTS (
            SELECT 1
            FROM @EmbeddingLinks el
            WHERE NOT EXISTS (
                SELECT 1
                FROM [dbo].[BinaryEmbeddingStores] bes
                WHERE bes.[Id] = el.[BinaryEmbeddingsStoreId]
            )
        )
            RAISERROR('One or more BinaryEmbeddingsStoreId values do not exist.', 16, 1);

        -- Prevent duplicate store links inside the same call
        IF EXISTS (
            SELECT [BinaryEmbeddingsStoreId]
            FROM @EmbeddingLinks
            GROUP BY [BinaryEmbeddingsStoreId]
            HAVING COUNT(*) > 1
        )
            RAISERROR('Duplicate BinaryEmbeddingsStoreId values are not allowed in the same file.', 16, 1);

        /* ---------- Insert file ---------- */
        INSERT INTO [dbo].[ServiceRequestFiles]
        (
            [PublicId],
            [ServiceOperationId],
            [FileFormat],
            [Name],
            [CompressedData],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [IsActive],
            [CreatedAt],
            [CreatedBy]
        )
        VALUES
        (
            @NewPublicId,
            @ServiceOperationId,
            @FileFormat,
            @Name,
            @CompressedData,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @IsActive,
            GETDATE(),
            @ResolvedUser
        );

        SET @NewFileId = CONVERT(INT, SCOPE_IDENTITY());

        /* ---------- Insert embedding links ---------- */
        INSERT INTO [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks]
        (
            [ServiceRequestFileId],
            [ElementName],
            [XmlPath],
            [BinaryEmbeddingsStoreId],
            [Name],
            [AdditionalDetails],
            [CreatedAt],
            [CreatedBy]
        )
        SELECT
            @NewFileId,
            el.[ElementName],
            el.[XmlPath],
            el.[BinaryEmbeddingsStoreId],
            el.[Name],
            el.[AdditionalDetails],
            GETDATE(),
            @ResolvedUser
        FROM @EmbeddingLinks el;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        /* ---------- Result set 1: File ---------- */
        SELECT
            f.[Id]                      AS ServiceRequestFileId,
            f.[PublicId],
            f.[ServiceOperationId],
            f.[FileFormat],
            f.[Name],
            f.[UncompressedSizeBytes],
            f.[CompressionAlgorithmType],
            f.[RecordVersion],
            f.[IsActive],
            f.[CreatedAt],
            f.[CreatedBy],
            CAST(1 AS BIT)              AS WasCreated,
            'Created'                   AS SaveResult
        FROM [dbo].[ServiceRequestFiles] f
        WHERE f.[Id] = @NewFileId;

        /* ---------- Result set 2: Links ---------- */
        SELECT
            l.[Id]                      AS LinkId,
            l.[PublicId],
            l.[ServiceRequestFileId],
            l.[ElementName],
            l.[XmlPath],
            l.[BinaryEmbeddingsStoreId],
            l.[Name],
            l.[AdditionalDetails],
            l.[CreatedAt],
            l.[CreatedBy]
        FROM [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks] l
        WHERE l.[ServiceRequestFileId] = @NewFileId
        ORDER BY l.[Id];
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
