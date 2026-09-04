/*
    Stored Procedure: usp_GetElementFrequency
    Description: Returns frequency of elements across files.
*/
CREATE PROCEDURE [dbo].[usp_GetElementFrequency]
    @ElementType VARCHAR(10) = NULL, -- 'XML', 'JSON', 'PDF', or NULL for all
    @MinFrequency INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    WITH ElementFreq AS (
        SELECT 
            'XML' AS ElementType,
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
        GROUP BY xele.[XmlPath], xes.[ElementValue]
        
        UNION ALL
        
        SELECT 
            'JSON' AS ElementType,
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
        GROUP BY jele.[JsonPath], jes.[ElementValue]

        UNION ALL

        SELECT 
            'PDF' AS ElementType,
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
        GROUP BY pele.[ElementType], pes.[ElementValue]
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