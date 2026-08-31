/*
    View: v_IndexingFileElementSearch
    Description: Unified view of both XML and JSON file elements for searching.
*/
CREATE VIEW [dbo].[v_IndexingFileElementSearch]
AS
-- XML Elements
SELECT 
    'XML' AS ElementType,
    xele.[ElementId],
    xele.[XPathKeyPath] AS KeyPath,
    xele.[ElementValue],
    xele.[ValueHash],
    'String' AS ValueType,
    xmap.[RequestFileId],
    xmap.[ResponseFileId],
    srf.[Name] AS RequestFileName,
    srf2.[Name] AS ResponseFileName
FROM [dbo].[IndexingXmlFileElements] xele
INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
    ON xele.[ElementId] = xmap.[ElementId]
LEFT JOIN [dbo].[ServiceRequestFiles] srf 
    ON xmap.[RequestFileId] = srf.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
    ON xmap.[ResponseFileId] = srf2.[Id]

UNION ALL

-- JSON Elements
SELECT 
    'JSON' AS ElementType,
    jele.[ElementId],
    jele.[JsonPathKeyPath] AS KeyPath,
    jele.[ElementValue],
    jele.[ValueHash],
    jele.[ValueType],
    jmap.[RequestFileId],
    jmap.[ResponseFileId],
    srf.[Name] AS RequestFileName,
    srf2.[Name] AS ResponseFileName
FROM [dbo].[IndexingJsonFileElements] jele
INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
    ON jele.[ElementId] = jmap.[ElementId]
LEFT JOIN [dbo].[ServiceRequestFiles] srf 
    ON jmap.[RequestFileId] = srf.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
    ON jmap.[ResponseFileId] = srf2.[Id];
GO