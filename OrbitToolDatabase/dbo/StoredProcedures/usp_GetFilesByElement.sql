/*
    Stored Procedure: usp_GetFilesByElement
    Description: Returns all request/response files containing a specific element.
*/
CREATE PROCEDURE [dbo].[usp_GetFilesByElement]
    @ElementType VARCHAR(10), -- 'XML' or 'JSON'
    @KeyPath VARCHAR(400),
    @ElementValue NVARCHAR(450) = NULL, -- NULL to search by path only
    @IncludeContent BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @ElementType = 'XML'
    BEGIN
        SELECT 
            xmap.[RequestFileId],
            xmap.[ResponseFileId],
            srf.[Name] AS RequestFileName,
            srf2.[Name] AS ResponseFileName,
            xele.[XPathKeyPath] AS KeyPath,
            xele.[ElementValue],
            CASE 
                WHEN @IncludeContent = 1 AND xmap.[RequestFileId] IS NOT NULL THEN srf.[CompressedData]
                WHEN @IncludeContent = 1 AND xmap.[ResponseFileId] IS NOT NULL THEN srf2.[CompressedData]
                ELSE CAST(0x AS VARBINARY(1))
            END AS FileContent
        FROM [dbo].[IndexingXmlFileElements] xele
        INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
            ON xele.[ElementId] = xmap.[ElementId]
        LEFT JOIN [dbo].[ServiceRequestFiles] srf 
            ON xmap.[RequestFileId] = srf.[Id]
        LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
            ON xmap.[ResponseFileId] = srf2.[Id]
        WHERE xele.[XPathKeyPath] = @KeyPath
          AND (@ElementValue IS NULL OR xele.[ElementValue] = @ElementValue);
    END
    ELSE IF @ElementType = 'JSON'
    BEGIN
        SELECT 
            jmap.[RequestFileId],
            jmap.[ResponseFileId],
            srf.[Name] AS RequestFileName,
            srf2.[Name] AS ResponseFileName,
            jele.[JsonPathKeyPath] AS KeyPath,
            jele.[ElementValue],
            jele.[ValueType],
            CASE 
                WHEN @IncludeContent = 1 AND jmap.[RequestFileId] IS NOT NULL THEN srf.[CompressedData]
                WHEN @IncludeContent = 1 AND jmap.[ResponseFileId] IS NOT NULL THEN srf2.[CompressedData]
                ELSE CAST(0x AS VARBINARY(1))
            END AS FileContent
        FROM [dbo].[IndexingJsonFileElements] jele
        INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
            ON jele.[ElementId] = jmap.[ElementId]
        LEFT JOIN [dbo].[ServiceRequestFiles] srf 
            ON jmap.[RequestFileId] = srf.[Id]
        LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
            ON jmap.[ResponseFileId] = srf2.[Id]
        WHERE jele.[JsonPathKeyPath] = @KeyPath
          AND (@ElementValue IS NULL OR jele.[ElementValue] = @ElementValue);
    END
    ELSE
    BEGIN
        RAISERROR('Invalid ElementType. Must be "XML" or "JSON".', 16, 1);
        RETURN;
    END
END;
GO