/*
    Stored Procedure: usp_InsertOrGetIndexingJsonFileElements
    Description: Inserts a new JSON file element or returns the existing one if it already exists.
    Checks uniqueness by ElementName + JsonPath combination.
*/
CREATE PROCEDURE [dbo].[usp_InsertOrGetIndexingJsonFileElements]
    @ElementName NVARCHAR(400),
    @JsonPath NVARCHAR(400),
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
        FROM [dbo].[IndexingJsonFileElements] WITH (UPDLOCK, HOLDLOCK)
        WHERE [ElementName] = @ElementName
          AND [JsonPath] = @JsonPath;

        IF @ExistingId IS NOT NULL
        BEGIN
            -- Update the existing record
            UPDATE [dbo].[IndexingJsonFileElements]
            SET [ValueType] = @ValueType,
                [LastUpdatedAt] = GETDATE()
            WHERE [Id] = @ExistingId;

            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT
                [Id],
                [ElementName],
                [JsonPath],
                [ValueType],
                [CreatedAt],
                [LastUpdatedAt],
                0 AS IsNew
            FROM [dbo].[IndexingJsonFileElements]
            WHERE [Id] = @ExistingId;

            RETURN;
        END

        -- Insert new element
        INSERT INTO [dbo].[IndexingJsonFileElements] (
            [ElementName],
            [JsonPath],
            [ValueType],
            [CreatedAt],
            [LastUpdatedAt]
        )
        VALUES (
            @ElementName,
            @JsonPath,
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
            [JsonPath],
            [ValueType],
            [CreatedAt],
            [LastUpdatedAt],
            1 AS IsNew
        FROM [dbo].[IndexingJsonFileElements]
        WHERE [Id] = @ExistingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error inserting or getting JSON file element: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO