/*
    Stored Procedure: usp_InsertOrGetPdfFileElement
    Description: Inserts a new PDF file element or returns the existing one if it already exists.
    Checks uniqueness by ElementName + ElementType + PageNumber combination.
*/
CREATE PROCEDURE [dbo].[usp_InsertOrGetPdfFileElement]
    @ElementName NVARCHAR(400),
    @ElementType NVARCHAR(100),
    @PageNumber INT,
    @BoundingRectangle NVARCHAR(400),
    @ValueType NVARCHAR(20) = 'String',
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

        -- Check if element already exists
        SELECT @ExistingId = [Id]
        FROM [dbo].[IndexingPdfFileElements]
        WHERE [ElementName] = @ElementName
          AND [ElementType] = @ElementType
          AND [PageNumber] = @PageNumber;

        IF @ExistingId IS NOT NULL
        BEGIN
            -- Update the existing record
            UPDATE [dbo].[IndexingPdfFileElements]
            SET [BoundingRectangle] = @BoundingRectangle,
                [ValueType] = @ValueType,
                [UpdatedAt] = GETDATE()
            WHERE [Id] = @ExistingId;

            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT
                [Id],
                [ElementName],
                [ElementType],
                [PageNumber],
                [BoundingRectangle],
                [ValueType],
                [CreatedAt],
                [UpdatedAt],
                0 AS IsNew
            FROM [dbo].[IndexingPdfFileElements]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new element
        INSERT INTO [dbo].[IndexingPdfFileElements] (
            [ElementName],
            [ElementType],
            [PageNumber],
            [BoundingRectangle],
            [ValueType],
            [CreatedAt],
            [UpdatedAt]
        )
        VALUES (
            @ElementName,
            @ElementType,
            @PageNumber,
            @BoundingRectangle,
            @ValueType,
            GETDATE(),
            NULL
        );

        SET @ExistingId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id],
            [ElementName],
            [ElementType],
            [PageNumber],
            [BoundingRectangle],
            [ValueType],
            [CreatedAt],
            [UpdatedAt],
            1 AS IsNew
        FROM [dbo].[IndexingPdfFileElements]
        WHERE [Id] = @ExistingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO