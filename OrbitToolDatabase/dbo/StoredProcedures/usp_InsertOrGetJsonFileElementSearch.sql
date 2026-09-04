/*
    Stored Procedure: usp_InsertOrGetJsonFileElementSearch
    Description: Inserts a new JSON file element search entry or returns the existing one.
    Checks uniqueness by IndexingJsonFileElementId + ElementValue combination.
*/
CREATE PROCEDURE [dbo].[usp_InsertOrGetJsonFileElementSearch]
    @IndexingJsonFileElementId BIGINT,
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
        IF NOT EXISTS (SELECT 1 FROM [dbo].[IndexingJsonFileElements] WHERE [Id] = @IndexingJsonFileElementId)
        BEGIN
            RAISERROR('IndexingJsonFileElement with Id %I64d not found.', 16, 1, @IndexingJsonFileElementId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if search entry already exists
        SELECT @ExistingId = [Id]
        FROM [dbo].[IndexingJsonFileElementSearch]
        WHERE [IndexingJsonFileElementId] = @IndexingJsonFileElementId
          AND [ElementValue] = @ElementValue;

        IF @ExistingId IS NOT NULL
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT
                [Id],
                [IndexingJsonFileElementId],
                [ElementValue],
                [CreatedAt],
                0 AS IsNew
            FROM [dbo].[IndexingJsonFileElementSearch]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new search entry
        INSERT INTO [dbo].[IndexingJsonFileElementSearch] (
            [IndexingJsonFileElementId],
            [ElementValue],
            [CreatedAt]
        )
        VALUES (
            @IndexingJsonFileElementId,
            @ElementValue,
            GETDATE()
        );

        SET @ExistingId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id],
            [IndexingJsonFileElementId],
            [ElementValue],
            [CreatedAt],
            1 AS IsNew
        FROM [dbo].[IndexingJsonFileElementSearch]
        WHERE [Id] = @ExistingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO