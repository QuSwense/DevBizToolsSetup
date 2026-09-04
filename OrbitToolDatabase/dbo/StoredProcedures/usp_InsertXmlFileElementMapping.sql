/*
    Stored Procedure: usp_InsertXmlFileElementMapping
    Description: Inserts a mapping between an XML file element search entry and a request or response file.
    Validates that exactly one of RequestFileId or ResponseFileId is provided.
*/
CREATE PROCEDURE [dbo].[usp_InsertXmlFileElementMapping]
    @IndexingXmlFileElementSearchId BIGINT,
    @RequestFileId INT = NULL,
    @ResponseFileId INT = NULL,
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

        -- Validate that exactly one file reference is provided
        IF (@RequestFileId IS NULL AND @ResponseFileId IS NULL)
           OR (@RequestFileId IS NOT NULL AND @ResponseFileId IS NOT NULL)
        BEGIN
            RAISERROR('Exactly one of @RequestFileId or @ResponseFileId must be provided.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate that the search entry exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[IndexingXmlFileElementSearch] WHERE [Id] = @IndexingXmlFileElementSearchId)
        BEGIN
            RAISERROR('IndexingXmlFileElementSearch with Id %I64d not found.', 16, 1, @IndexingXmlFileElementSearchId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate request file exists if provided
        IF @RequestFileId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM [dbo].[ServiceRequestFiles] WHERE [Id] = @RequestFileId AND [IsActive] = 1)
        BEGIN
            RAISERROR('ServiceRequestFile with Id %d not found or inactive.', 16, 1, @RequestFileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validate response file exists if provided
        IF @ResponseFileId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM [dbo].[ServiceResponseFiles] WHERE [Id] = @ResponseFileId AND [IsActive] = 1)
        BEGIN
            RAISERROR('ServiceResponseFile with Id %d not found or inactive.', 16, 1, @ResponseFileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate mapping
        IF EXISTS (
            SELECT 1 FROM [dbo].[IndexingXmlFileElementMappings]
            WHERE [IndexingXmlFileElementSearchId] = @IndexingXmlFileElementSearchId
              AND ((@RequestFileId IS NOT NULL AND [RequestFileId] = @RequestFileId)
                   OR (@ResponseFileId IS NOT NULL AND [ResponseFileId] = @ResponseFileId))
        )
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            -- Return the existing mapping
            SELECT
                [Id],
                [RequestFileId],
                [ResponseFileId],
                [IndexingXmlFileElementSearchId],
                0 AS IsNew
            FROM [dbo].[IndexingXmlFileElementMappings]
            WHERE [IndexingXmlFileElementSearchId] = @IndexingXmlFileElementSearchId
              AND ((@RequestFileId IS NOT NULL AND [RequestFileId] = @RequestFileId)
                   OR (@ResponseFileId IS NOT NULL AND [ResponseFileId] = @ResponseFileId));

            RETURN;
        END

        -- Insert new mapping
        INSERT INTO [dbo].[IndexingXmlFileElementMappings] (
            [RequestFileId],
            [ResponseFileId],
            [IndexingXmlFileElementSearchId]
        )
        VALUES (
            @RequestFileId,
            @ResponseFileId,
            @IndexingXmlFileElementSearchId
        );

        SET @NewId = SCOPE_IDENTITY();

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        SELECT
            [Id],
            [RequestFileId],
            [ResponseFileId],
            [IndexingXmlFileElementSearchId],
            1 AS IsNew
        FROM [dbo].[IndexingXmlFileElementMappings]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO