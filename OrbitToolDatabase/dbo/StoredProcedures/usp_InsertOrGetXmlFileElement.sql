/*
    Stored Procedure: usp_InsertOrGetXmlFileElement
    Description: Inserts a new XML file element or returns the existing one if it already exists.
    Checks uniqueness by ElementName + XmlPath combination.
*/
CREATE PROCEDURE [dbo].[usp_InsertOrGetXmlFileElement]
    @ElementName NVARCHAR(400),
    @XmlPath NVARCHAR(400),
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
        FROM [dbo].[IndexingXmlFileElements]
        WHERE [ElementName] = @ElementName
          AND [XmlPath] = @XmlPath;

        IF @ExistingId IS NOT NULL
        BEGIN
            -- Update the existing record
            UPDATE [dbo].[IndexingXmlFileElements]
            SET [ValueType] = @ValueType,
                [UpdatedAt] = GETDATE()
            WHERE [Id] = @ExistingId;

            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT
                [Id],
                [ElementName],
                [XmlPath],
                [ValueType],
                [CreatedAt],
                [UpdatedAt],
                0 AS IsNew
            FROM [dbo].[IndexingXmlFileElements]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new element
        INSERT INTO [dbo].[IndexingXmlFileElements] (
            [ElementName],
            [XmlPath],
            [ValueType],
            [CreatedAt],
            [UpdatedAt]
        )
        VALUES (
            @ElementName,
            @XmlPath,
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
            [XmlPath],
            [ValueType],
            [CreatedAt],
            [UpdatedAt],
            1 AS IsNew
        FROM [dbo].[IndexingXmlFileElements]
        WHERE [Id] = @ExistingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO