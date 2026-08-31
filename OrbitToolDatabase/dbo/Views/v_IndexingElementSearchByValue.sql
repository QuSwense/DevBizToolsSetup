/*
    View: v_IndexingElementSearchByValue
    Description: Search elements by value with file context.
*/
CREATE VIEW [dbo].[v_IndexingElementSearchByValue]
AS
SELECT 
    s.[ElementType],
    s.[ElementId],
    s.[KeyPath],
    s.[ElementValue],
    s.[ValueType],
    s.[RequestFileId],
    s.[ResponseFileId],
    s.[RequestFileName],
    s.[ResponseFileName],
    -- File type indicator
    CASE 
        WHEN s.[RequestFileId] IS NOT NULL THEN 'Request'
        WHEN s.[ResponseFileId] IS NOT NULL THEN 'Response'
        ELSE 'Unknown'
    END AS SourceFileType,
    -- Full path display
    CASE 
        WHEN s.[RequestFileId] IS NOT NULL THEN 
            CONCAT('Request: ', s.[RequestFileName])
        WHEN s.[ResponseFileId] IS NOT NULL THEN 
            CONCAT('Response: ', s.[ResponseFileName])
        ELSE 'Unknown'
    END AS FileDisplayName
FROM [dbo].[v_IndexingFileElementSearch] s;
GO