/*
    Stored Procedure: usp_SearchElements
    Description: Full-text search across all indexed elements.
*/
CREATE PROCEDURE [dbo].[usp_SearchElements]
    @SearchTerm NVARCHAR(4000),
    @ElementType VARCHAR(10) = NULL, -- 'XML', 'JSON', or NULL for both
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
        ft.[RANK] AS RelevanceScore
    FROM FREETEXTTABLE([dbo].[IndexingFileElementSearch], [ElementValue], @SearchTerm) AS ft
    INNER JOIN [dbo].[IndexingFileElementSearch] s ON s.[Id] = ft.[KEY]
    LEFT JOIN [dbo].[ServiceRequestFiles] srf ON s.[RequestFileId] = srf.[Id]
    LEFT JOIN [dbo].[ServiceResponseFiles] srf2 ON s.[ResponseFileId] = srf2.[Id]
    WHERE (@ElementType IS NULL OR s.[ElementType] = @ElementType)
    ORDER BY ft.[RANK] DESC;
END;
GO