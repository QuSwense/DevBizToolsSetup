/*
    Stored Procedure: usp_GetElementFrequency
    Description: Returns frequency of elements across files.
*/
CREATE PROCEDURE [dbo].[usp_GetElementFrequency]
    @ElementType VARCHAR(10) = NULL, -- 'XML', 'JSON', or NULL for both
    @MinFrequency INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    WITH ElementFreq AS (
        SELECT 
            'XML' AS ElementType,
            xele.[XPathKeyPath] AS KeyPath,
            xele.[ElementValue],
            COUNT(DISTINCT xmap.[RequestFileId]) AS RequestFileCount,
            COUNT(DISTINCT xmap.[ResponseFileId]) AS ResponseFileCount,
            COUNT(*) AS TotalMappings
        FROM [dbo].[IndexingXmlFileElements] xele
        INNER JOIN [dbo].[IndexingXmlFileElementMappings] xmap 
            ON xele.[ElementId] = xmap.[ElementId]
        GROUP BY xele.[XPathKeyPath], xele.[ElementValue]
        
        UNION ALL
        
        SELECT 
            'JSON' AS ElementType,
            jele.[JsonPathKeyPath] AS KeyPath,
            jele.[ElementValue],
            COUNT(DISTINCT jmap.[RequestFileId]) AS RequestFileCount,
            COUNT(DISTINCT jmap.[ResponseFileId]) AS ResponseFileCount,
            COUNT(*) AS TotalMappings
        FROM [dbo].[IndexingJsonFileElements] jele
        INNER JOIN [dbo].[IndexingJsonFileElementMappings] jmap 
            ON jele.[ElementId] = jmap.[ElementId]
        GROUP BY jele.[JsonPathKeyPath], jele.[ElementValue]
    )
    SELECT 
        ElementType,
        KeyPath,
        ElementValue,
        RequestFileCount,
        ResponseFileCount,
        TotalMappings,
        RequestFileCount + ResponseFileCount AS TotalFileCount
    FROM ElementFreq
    WHERE TotalMappings >= @MinFrequency
      AND (@ElementType IS NULL OR ElementType = @ElementType)
    ORDER BY TotalMappings DESC;
END;
GO