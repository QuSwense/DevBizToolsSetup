/*
    View: v_IndexingPendingQueue
    Description: Unified view of files pending indexing.
*/
CREATE VIEW [dbo].[v_IndexingPendingQueue]
AS
-- Request files pending indexing
SELECT 
    'Request' AS FileType,
    sris.[ServiceRequestFileId] AS FileId,
    srf.[Name] AS FileName,
    srf.[FileFormat],
    sris.[IndexingStatus],
    sris.[LastIndexedAt],
    sris.[CreatedAt],
    sris.[IndexingFailureReason]
FROM [dbo].[ServiceRequestIndexingStatus] sris
INNER JOIN [dbo].[ServiceRequestFiles] srf ON sris.[ServiceRequestFileId] = srf.[Id]
WHERE sris.[IndexingStatus] IN ('Pending', 'Failed')

UNION ALL

-- Response files pending indexing
SELECT 
    'Response' AS FileType,
    sris.[ServiceResponseFileId] AS FileId,
    srf.[Name] AS FileName,
    srf.[FileFormat],
    sris.[IndexingStatus],
    sris.[LastIndexedAt],
    sris.[CreatedAt],
    sris.[IndexingFailureReason]
FROM [dbo].[ServiceResponseIndexingStatus] sris
INNER JOIN [dbo].[ServiceResponseFiles] srf ON sris.[ServiceResponseFileId] = srf.[Id]
WHERE sris.[IndexingStatus] IN ('Pending', 'Failed');
GO