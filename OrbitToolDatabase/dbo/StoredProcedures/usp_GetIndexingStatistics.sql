/*
    Stored Procedure: usp_GetIndexingStatistics
    Description: Returns statistics about the indexing system.
*/
CREATE PROCEDURE [dbo].[usp_GetIndexingStatistics]
AS
BEGIN
    SET NOCOUNT ON;

    -- XML Statistics
    SELECT 
        'XML' AS ElementType,
        (SELECT COUNT(*) FROM [dbo].[IndexingXmlFileElements]) AS UniqueElements,
        (SELECT COUNT(*) FROM [dbo].[IndexingXmlFileElementMappings]) AS TotalMappings,
        (SELECT COUNT(DISTINCT [RequestFileId]) FROM [dbo].[IndexingXmlFileElementMappings] WHERE [RequestFileId] IS NOT NULL) AS RequestFiles,
        (SELECT COUNT(DISTINCT [ResponseFileId]) FROM [dbo].[IndexingXmlFileElementMappings] WHERE [ResponseFileId] IS NOT NULL) AS ResponseFiles,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS RequestCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS RequestPending,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS RequestFailed,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS ResponseCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS ResponsePending,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS ResponseFailed

    UNION ALL

    -- JSON Statistics
    SELECT 
        'JSON' AS ElementType,
        (SELECT COUNT(*) FROM [dbo].[IndexingJsonFileElements]) AS UniqueElements,
        (SELECT COUNT(*) FROM [dbo].[IndexingJsonFileElementMappings]) AS TotalMappings,
        (SELECT COUNT(DISTINCT [RequestFileId]) FROM [dbo].[IndexingJsonFileElementMappings] WHERE [RequestFileId] IS NOT NULL) AS RequestFiles,
        (SELECT COUNT(DISTINCT [ResponseFileId]) FROM [dbo].[IndexingJsonFileElementMappings] WHERE [ResponseFileId] IS NOT NULL) AS ResponseFiles,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS RequestCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS RequestPending,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS RequestFailed,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS ResponseCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS ResponsePending,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS ResponseFailed

    UNION ALL

    -- Combined Total
    SELECT 
        'TOTAL' AS ElementType,
        (SELECT COUNT(*) FROM [dbo].[IndexingXmlFileElements]) + (SELECT COUNT(*) FROM [dbo].[IndexingJsonFileElements]) AS UniqueElements,
        (SELECT COUNT(*) FROM [dbo].[IndexingXmlFileElementMappings]) + (SELECT COUNT(*) FROM [dbo].[IndexingJsonFileElementMappings]) AS TotalMappings,
        (SELECT COUNT(DISTINCT [RequestFileId]) FROM [dbo].[IndexingXmlFileElementMappings] WHERE [RequestFileId] IS NOT NULL) 
            + (SELECT COUNT(DISTINCT [RequestFileId]) FROM [dbo].[IndexingJsonFileElementMappings] WHERE [RequestFileId] IS NOT NULL) AS RequestFiles,
        (SELECT COUNT(DISTINCT [ResponseFileId]) FROM [dbo].[IndexingXmlFileElementMappings] WHERE [ResponseFileId] IS NOT NULL) 
            + (SELECT COUNT(DISTINCT [ResponseFileId]) FROM [dbo].[IndexingJsonFileElementMappings] WHERE [ResponseFileId] IS NOT NULL) AS ResponseFiles,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS RequestCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS RequestPending,
        (SELECT COUNT(*) FROM [dbo].[ServiceRequestIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS RequestFailed,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Completed') AS ResponseCompleted,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Pending') AS ResponsePending,
        (SELECT COUNT(*) FROM [dbo].[ServiceResponseIndexingStatus] WHERE [IndexingStatus] = 'Failed') AS ResponseFailed;
END;
GO