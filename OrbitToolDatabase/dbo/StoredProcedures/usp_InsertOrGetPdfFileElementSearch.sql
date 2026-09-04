/*
    Stored Procedure: usp_InsertOrGetPdfFileElementSearch
    Description: Inserts a new PDF file element search entry or returns the existing one.
    Checks uniqueness by IndexingPdfFileElementId + ElementValue combination.
*/
CREATE PROCEDURE [dbo].[usp_InsertOrGetPdfFileElementSearch]
    @IndexingPdfFileElementId BIGINT,
    @ElementValue NVARCHAR(800),
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
        DECLARE @ExistingId BIGINT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Validate that the parent element exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[IndexingPdfFileElements] WHERE [Id] = @IndexingPdfFileElementId)
        BEGIN
            RAISERROR('IndexingPdfFileElement with Id %I64d not found.', 16, 1, @IndexingPdfFileElementId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if search entry already exists
        SELECT @ExistingId = [Id]
        FROM [dbo].[IndexingPdfFileElementSearch]
        WHERE [IndexingPdfFileElementId] = @IndexingPdfFileElementId
          AND [ElementValue] = @ElementValue;

        IF @ExistingId IS NOT NULL
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT
                [Id],
                [IndexingPdfFileElementId],
                [ElementValue],
                [CreatedAt],
                0 AS IsNew
            FROM [dbo].[IndexingPdfFileElementSearch]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new search entry
        INSERT INTO [dbo].[IndexingPdfFileElementSearch] (
            [IndexingPdfFileElementId],
            [ElementValue],
            [CreatedAt]
        )
        VALUES (
            @IndexingPdfFileElementId,
            @ElementValue,
            GETDATE()
        );

        SET @ExistingId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id],
            [IndexingPdfFileElementId],
            [ElementValue],
            [CreatedAt],
            1 AS IsNew
        FROM [dbo].[IndexingPdfFileElementSearch]
        WHERE [Id] = @ExistingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO