/*
    Stored Procedure: usp_SearchElements
    Description: Search across all indexed elements using LIKE pattern matching.
    Note: This replaces the previous FREETEXTTABLE-based search since the
    denormalized IndexingFileElementSearch table has been replaced by per-type
    element search tables.
*/
CREATE PROCEDURE [dbo].[usp_SearchElements]
    @SearchTerm NVARCHAR(4000),
    @ElementType VARCHAR(10) = NULL, -- 'XML', 'JSON', 'PDF', or NULL for all
    @MaxResults INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@MaxResults)
        s.[ElementType],
        s.[ElementId],
        s.[KeyPath],
        s.[ElementValue],
        s.[ValueType],
        s.[RequestFileId],
        s.[ResponseFileId],
        srf.[Name] AS RequestFileName,
        srf2.[Name] AS ResponseFileName,
        CASE 
            WHEN s.[RequestFileId] IS NOT NULL THEN 'Request'
            WHEN s.[ResponseFileId] IS NOT NULL THEN 'Response'
            ELSE 'Unknown'
        END AS SourceFileType,
        CASE 
            WHEN s.[RequestFileId] IS NOT NULL THEN CONCAT('Request: ', srf.[Name])
            WHEN s.[ResponseFileId] IS NOT NULL THEN CONCAT('Response: ', srf2.[Name])
            ELSE 'Unknown'
        END AS FileDisplayName,
        1 AS RelevanceScore
    FROM [dbo].[v_IndexingFileElementSearch] s
    LEFT JOIN [dbo].[ServiceRequestFiles] srf ON s.[RequestFileId] = srf.[Id]
    LEFT JOIN [dbo].[ServiceResponseFiles] srf2 ON s.[ResponseFileId] = srf2.[Id]
    WHERE (@ElementType IS NULL OR s.[ElementType] = @ElementType)
      AND (s.[ElementValue] LIKE N'%' + @SearchTerm + N'%'
           OR s.[ElementName] LIKE N'%' + @SearchTerm + N'%'
           OR s.[KeyPath] LIKE N'%' + @SearchTerm + N'%')
    ORDER BY LEN(s.[ElementValue]) ASC;
END;
GO