/*
    Stored Procedure: usp_InsertPdfFileElementMapping
    Description: Inserts a mapping between a PDF file element search entry and a binary embedding store entry.
    PDF elements are linked to BinaryEmbeddingsStore rather than request/response files.
*/
CREATE PROCEDURE [dbo].[usp_InsertPdfFileElementMapping]
    @IndexingPdfFileElementSearchId BIGINT,
    @BinaryEmbeddingsStoreId INT = NULL,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NewId BIGINT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate that the search entry exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[IndexingPdfFileElementSearch] WHERE [Id] = @IndexingPdfFileElementSearchId)
        BEGIN
            RAISERROR('IndexingPdfFileElementSearch with Id %I64d not found.', 16, 1, @IndexingPdfFileElementSearchId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate binary embedding exists if provided
        IF @BinaryEmbeddingsStoreId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM [dbo].[BinaryEmbeddingsStore] WHERE [Id] = @BinaryEmbeddingsStoreId)
        BEGIN
            RAISERROR('BinaryEmbeddingsStore with Id %d not found.', 16, 1, @BinaryEmbeddingsStoreId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate mapping
        IF EXISTS (
            SELECT 1 FROM [dbo].[IndexingPdfFileElementMappings]
            WHERE [IndexingPdfFileElementSearchId] = @IndexingPdfFileElementSearchId
              AND ((@BinaryEmbeddingsStoreId IS NOT NULL AND [BinaryEmbeddingsStoreId] = @BinaryEmbeddingsStoreId)
                   OR (@BinaryEmbeddingsStoreId IS NULL AND [BinaryEmbeddingsStoreId] IS NULL))
        )
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            -- Return the existing mapping
            SELECT
                [Id],
                [BinaryEmbeddingsStoreId],
                [IndexingPdfFileElementSearchId],
                0 AS IsNew
            FROM [dbo].[IndexingPdfFileElementMappings]
            WHERE [IndexingPdfFileElementSearchId] = @IndexingPdfFileElementSearchId
              AND ((@BinaryEmbeddingsStoreId IS NOT NULL AND [BinaryEmbeddingsStoreId] = @BinaryEmbeddingsStoreId)
                   OR (@BinaryEmbeddingsStoreId IS NULL AND [BinaryEmbeddingsStoreId] IS NULL));

            RETURN;
        END

        -- Insert new mapping
        INSERT INTO [dbo].[IndexingPdfFileElementMappings] (
            [BinaryEmbeddingsStoreId],
            [IndexingPdfFileElementSearchId]
        )
        VALUES (
            @BinaryEmbeddingsStoreId,
            @IndexingPdfFileElementSearchId
        );

        SET @NewId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id],
            [BinaryEmbeddingsStoreId],
            [IndexingPdfFileElementSearchId],
            1 AS IsNew
        FROM [dbo].[IndexingPdfFileElementMappings]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO