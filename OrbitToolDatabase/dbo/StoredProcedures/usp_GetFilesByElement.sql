/*
    Stored Procedure: usp_GetFilesByElement
    Description: Returns all request/response files containing a specific element.
*/
CREATE PROCEDURE [dbo].[usp_GetFilesByElement]
    @ElementType VARCHAR(10), -- 'XML', 'JSON', or 'PDF'
    @KeyPath NVARCHAR(400),
    @ElementValue NVARCHAR(800) = NULL, -- NULL to search by path only
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
            xele.[XmlPath] AS KeyPath,
            xes.[ElementValue],
            CASE 
                WHEN @IncludeContent = 1 AND xmap.[RequestFileId] IS NOT NULL THEN srf.[CompressedData]
                WHEN @IncludeContent = 1 AND xmap.[ResponseFileId] IS NOT NULL THEN srf2.[CompressedData]
                ELSE CAST(0x AS VARBINARY(1))
            END AS FileContent
        FROM [dbo].[IndexingXmlFileElements] xele
        INNER JOIN [dbo].[IndexingXmlFileElementSearch] xes 
            ON xele.[Id] = xes.[IndexingXmlFileElementId]
        INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
            ON xes.[Id] = xmap.[IndexingXmlFileElementSearchId]
        LEFT JOIN [dbo].[ServiceRequestFiles] srf 
            ON xmap.[RequestFileId] = srf.[Id]
        LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
            ON xmap.[ResponseFileId] = srf2.[Id]
        WHERE xele.[XmlPath] = @KeyPath
          AND (@ElementValue IS NULL OR xes.[ElementValue] = @ElementValue);
    END
    ELSE IF @ElementType = 'JSON'
    BEGIN
        SELECT 
            jmap.[RequestFileId],
            jmap.[ResponseFileId],
            srf.[Name] AS RequestFileName,
            srf2.[Name] AS ResponseFileName,
            jele.[JsonPath] AS KeyPath,
            jes.[ElementValue],
            jele.[ValueType],
            CASE 
                WHEN @IncludeContent = 1 AND jmap.[RequestFileId] IS NOT NULL THEN srf.[CompressedData]
                WHEN @IncludeContent = 1 AND jmap.[ResponseFileId] IS NOT NULL THEN srf2.[CompressedData]
                ELSE CAST(0x AS VARBINARY(1))
            END AS FileContent
        FROM [dbo].[IndexingJsonFileElements] jele
        INNER JOIN [dbo].[IndexingJsonFileElementSearch] jes 
            ON jele.[Id] = jes.[IndexingJsonFileElementId]
        INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
            ON jes.[Id] = jmap.[IndexingJsonFileElementSearchId]
        LEFT JOIN [dbo].[ServiceRequestFiles] srf 
            ON jmap.[RequestFileId] = srf.[Id]
        LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
            ON jmap.[ResponseFileId] = srf2.[Id]
        WHERE jele.[JsonPath] = @KeyPath
          AND (@ElementValue IS NULL OR jes.[ElementValue] = @ElementValue);
    END
    ELSE IF @ElementType = 'PDF'
    BEGIN
        SELECT 
            NULL AS RequestFileId,
            NULL AS ResponseFileId,
            NULL AS RequestFileName,
            NULL AS ResponseFileName,
            pele.[ElementType] AS KeyPath,
            pes.[ElementValue],
            pele.[ValueType],
            CAST(0x AS VARBINARY(1)) AS FileContent
        FROM [dbo].[IndexingPdfFileElements] pele
        INNER JOIN [dbo].[IndexingPdfFileElementSearch] pes 
            ON pele.[Id] = pes.[IndexingPdfFileElementId]
        INNER JOIN [dbo].[IndexingPdfFileElementMappings] pmap 
            ON pes.[Id] = pmap.[IndexingPdfFileElementSearchId]
        WHERE pele.[ElementType] = @KeyPath
          AND (@ElementValue IS NULL OR pes.[ElementValue] = @ElementValue);
    END
    ELSE
    BEGIN
        RAISERROR('Invalid ElementType. Must be "XML", "JSON", or "PDF".', 16, 1);
        RETURN;
    END
END;
GO