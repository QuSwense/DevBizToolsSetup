/*
    View: v_IndexingElementUsageStats
    Description: Statistics on element usage across files.
*/
CREATE VIEW [dbo].[v_IndexingElementUsageStats]
AS
WITH ElementUsage AS (
    SELECT 
        'XML' AS ElementType,
        ele.[ElementId],
        ele.[XPathKeyPath] AS KeyPath,
        ele.[ElementValue],
        COUNT(DISTINCT xmap.[RequestFileId]) AS RequestFileCount,
        COUNT(DISTINCT xmap.[ResponseFileId]) AS ResponseFileCount,
        COUNT(*) AS TotalMappings
    FROM [dbo].[IndexingXmlFileElements] ele
    INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
        ON ele.[ElementId] = xmap.[ElementId]
    GROUP BY ele.[ElementId], ele.[XPathKeyPath], ele.[ElementValue]
    
    UNION ALL
    
    SELECT 
        'JSON' AS ElementType,
        ele.[ElementId],
        ele.[JsonPathKeyPath] AS KeyPath,
        ele.[ElementValue],
        COUNT(DISTINCT jmap.[RequestFileId]) AS RequestFileCount,
        COUNT(DISTINCT jmap.[ResponseFileId]) AS ResponseFileCount,
        COUNT(*) AS TotalMappings
    FROM [dbo].[IndexingJsonFileElements] ele
    INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
        ON ele.[ElementId] = jmap.[ElementId]
    GROUP BY ele.[ElementId], ele.[JsonPathKeyPath], ele.[ElementValue]
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