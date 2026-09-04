/*
    View: v_IndexingFileElementSearch
    Description: Unified view of XML, JSON, and PDF file elements for searching.
*/
CREATE VIEW [dbo].[v_IndexingFileElementSearch]
AS
-- XML Elements
SELECT 
    'XML' AS ElementType,
    xele.[Id] AS ElementId,
    xele.[ElementName],
    xele.[XmlPath] AS KeyPath,
    xes.[ElementValue],
    xele.[ValueType],
    xmap.[RequestFileId],
    xmap.[ResponseFileId],
    srf.[Name] AS RequestFileName,
    srf2.[Name] AS ResponseFileName
FROM [dbo].[IndexingXmlFileElements] xele
INNER JOIN [dbo].[IndexingXmlFileElementSearch] xes 
    ON xele.[Id] = xes.[IndexingXmlFileElementId]
INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
    ON xes.[Id] = xmap.[IndexingXmlFileElementSearchId]
LEFT JOIN [dbo].[ServiceRequestFiles] srf 
    ON xmap.[RequestFileId] = srf.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
    ON xmap.[ResponseFileId] = srf2.[Id]

UNION ALL

-- JSON Elements
SELECT 
    'JSON' AS ElementType,
    jele.[Id] AS ElementId,
    jele.[ElementName],
    jele.[JsonPath] AS KeyPath,
    jes.[ElementValue],
    jele.[ValueType],
    jmap.[RequestFileId],
    jmap.[ResponseFileId],
    srf.[Name] AS RequestFileName,
    srf2.[Name] AS ResponseFileName
FROM [dbo].[IndexingJsonFileElements] jele
INNER JOIN [dbo].[IndexingJsonFileElementSearch] jes 
    ON jele.[Id] = jes.[IndexingJsonFileElementId]
INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
    ON jes.[Id] = jmap.[IndexingJsonFileElementSearchId]
LEFT JOIN [dbo].[ServiceRequestFiles] srf 
    ON jmap.[RequestFileId] = srf.[Id]
LEFT JOIN [dbo].[ServiceResponseFiles] srf2 
    ON jmap.[ResponseFileId] = srf2.[Id]

UNION ALL

-- PDF Elements
SELECT 
    'PDF' AS ElementType,
    pele.[Id] AS ElementId,
    pele.[ElementName],
    pele.[ElementType] AS KeyPath,
    pes.[ElementValue],
    pele.[ValueType],
    NULL AS RequestFileId,
    NULL AS ResponseFileId,
    NULL AS RequestFileName,
    NULL AS ResponseFileName
FROM [dbo].[IndexingPdfFileElements] pele
INNER JOIN [dbo].[IndexingPdfFileElementSearch] pes 
    ON pele.[Id] = pes.[IndexingPdfFileElementId]
INNER JOIN [dbo].[IndexingPdfFileElementMappings] pmap 
    ON pes.[Id] = pmap.[IndexingPdfFileElementSearchId];
GO