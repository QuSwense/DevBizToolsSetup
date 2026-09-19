/*
    Table: IndexingServiceResponseFileStatus
    Description: Tracks the asynchronous background element-indexing state for response files.
    Logic:
    - Decoupled from ServiceRequestFiles to eliminate row-locking during execution writes.
    - Read and updated exclusively by the background indexing worker service.
*/
CREATE TABLE [dbo].[IndexingServiceResponseFileStatus] (
    -- Primary Key & Foreign Key pointing directly to the ServiceRequestFiles record.
    [ServiceResponseFileId] INT NOT NULL,
    -- Processing status state ('Pending', 'Processing', 'Completed', 'Failed').
    [IndexingStatus] VARCHAR(20) NOT NULL CONSTRAINT [DF_IndexingServiceResponseFileStatus_Status] DEFAULT 'Pending',
    -- Error message and stack trace detailing failure if IndexingStatus = 'Failed'.
    [IndexingFailureReason] NVARCHAR(MAX) NULL,
    -- Timestamp when background parsing successfully completed.
    [LastIndexedAt] DATETIME2(3) NULL,
    -- Timestamp when the status tracking entry was created.
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT [DF_IndexingServiceResponseFileStatus_CreatedAt] DEFAULT GETDATE(),
    -- Timestamp when the status was last updated by the background worker.
    [LastUpdatedAt] DATETIME2(3) NULL,

    CONSTRAINT [PK_IndexingServiceResponseFileStatus] PRIMARY KEY CLUSTERED ([ServiceResponseFileId] ASC),
    CONSTRAINT [CK_IndexingServiceResponseFileStatus_Status] CHECK ([IndexingStatus] IN ('Pending', 'Processing', 'Completed', 'Failed')),
    CONSTRAINT [FK_IndexingServiceResponseFileStatus_ServiceResponseFiles] FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id])
);
GO

-- Filtered queue index enabling the background worker to fetch unindexed response files efficiently.
CREATE NONCLUSTERED INDEX [IX_IndexingServiceResponseFileStatus_Pending] 
ON [dbo].[IndexingServiceResponseFileStatus] ([IndexingStatus] ASC, [CreatedAt] ASC) 
WHERE [IndexingStatus] IN ('Pending', 'Failed');
GO