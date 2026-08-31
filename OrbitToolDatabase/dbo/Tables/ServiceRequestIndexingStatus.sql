/*
    Table: ServiceRequestIndexingStatus
    Description: Tracks the asynchronous background element-indexing state for request files.
    Logic:
    - Decoupled from ServiceRequestFiles to eliminate row-locking during execution writes.
    - Read and updated exclusively by the background indexing worker service.
*/
CREATE TABLE [dbo].[ServiceRequestIndexingStatus] (
    -- Primary Key & Foreign Key pointing directly to the ServiceRequestFiles record.
    [ServiceRequestFileId] INT NOT NULL,
    -- Processing status state ('Pending', 'Processing', 'Completed', 'Failed').
    [IndexingStatus] VARCHAR(20) NOT NULL CONSTRAINT [DF_ServiceRequestIndexingStatus_Status] DEFAULT 'Pending',
    -- Error message and stack trace detailing failure if IndexingStatus = 'Failed'.
    [IndexingFailureReason] NVARCHAR(MAX) NULL,
    -- Timestamp when background parsing successfully completed.
    [LastIndexedAt] DATETIME NULL,
    -- Timestamp when the status tracking entry was created.
    [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_ServiceRequestIndexingStatus_CreatedAt] DEFAULT GETDATE(),

    CONSTRAINT [PK_ServiceRequestIndexingStatus] PRIMARY KEY CLUSTERED ([ServiceRequestFileId] ASC),
    CONSTRAINT [CK_ServiceRequestIndexingStatus_Status] CHECK ([IndexingStatus] IN ('Pending', 'Processing', 'Completed', 'Failed')),
    CONSTRAINT [FK_ServiceRequestIndexingStatus_ServiceRequestFiles] FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE
);
GO

-- Filtered queue index enabling the background worker to fetch unindexed request files efficiently.
CREATE NONCLUSTERED INDEX [IX_ServiceRequestIndexingStatus_Pending] 
ON [dbo].[ServiceRequestIndexingStatus] ([IndexingStatus] ASC, [CreatedAt] ASC) 
WHERE [IndexingStatus] IN ('Pending', 'Failed');
GO