/*
    View: v_IndexingElementUsageStats
    Description: Statistics on element usage across files.
*/
CREATE VIEW [dbo].[v_IndexingElementUsageStats]
AS
WITH ElementUsage AS (
    SELECT 
        'XML' AS ElementType,
        xele.[Id] AS ElementId,
        xele.[XmlPath] AS KeyPath,
        xes.[ElementValue],
        COUNT(DISTINCT xmap.[RequestFileId]) AS RequestFileCount,
        COUNT(DISTINCT xmap.[ResponseFileId]) AS ResponseFileCount,
        COUNT(*) AS TotalMappings
    FROM [dbo].[IndexingXmlFileElements] xele
    INNER JOIN [dbo].[IndexingXmlFileElementSearch] xes 
        ON xele.[Id] = xes.[IndexingXmlFileElementId]
    INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
        ON xes.[Id] = xmap.[IndexingXmlFileElementSearchId]
    GROUP BY xele.[Id], xele.[XmlPath], xes.[ElementValue]
    
    UNION ALL
    
    SELECT 
        'JSON' AS ElementType,
        jele.[Id] AS ElementId,
        jele.[JsonPath] AS KeyPath,
        jes.[ElementValue],
        COUNT(DISTINCT jmap.[RequestFileId]) AS RequestFileCount,
        COUNT(DISTINCT jmap.[ResponseFileId]) AS ResponseFileCount,
        COUNT(*) AS TotalMappings
    FROM [dbo].[IndexingJsonFileElements] jele
    INNER JOIN [dbo].[IndexingJsonFileElementSearch] jes 
        ON jele.[Id] = jes.[IndexingJsonFileElementId]
    INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
        ON jes.[Id] = jmap.[IndexingJsonFileElementSearchId]
    GROUP BY jele.[Id], jele.[JsonPath], jes.[ElementValue]

    UNION ALL

    SELECT 
        'PDF' AS ElementType,
        pele.[Id] AS ElementId,
        pele.[ElementType] AS KeyPath,
        pes.[ElementValue],
        0 AS RequestFileCount,
        0 AS ResponseFileCount,
        COUNT(*) AS TotalMappings
    FROM [dbo].[IndexingPdfFileElements] pele
    INNER JOIN [dbo].[IndexingPdfFileElementSearch] pes 
        ON pele.[Id] = pes.[IndexingPdfFileElementId]
    INNER JOIN [dbo].[IndexingPdfFileElementMappings] pmap 
        ON pes.[Id] = pmap.[IndexingPdfFileElementSearchId]
    GROUP BY pele.[Id], pele.[ElementType], pes.[ElementValue]
)
SELECT 
    ElementType,
    ElementId,
    KeyPath,
    ElementValue,
    RequestFileCount,
    ResponseFileCount,
    TotalMappings,
    TotalMappings - RequestFileCount - ResponseFileCount AS DuplicateCount,
    RANK() OVER (ORDER BY TotalMappings DESC) AS UsageRank
FROM ElementUsage;
GO