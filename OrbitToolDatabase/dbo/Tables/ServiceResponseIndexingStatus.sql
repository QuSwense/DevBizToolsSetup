/*
    Table: ServiceResponseIndexingStatus
    Description: Tracks the asynchronous background element-indexing state for response files.
    Logic:
    - Decoupled from ServiceResponseFiles to eliminate row-locking during high-frequency execution saves.
    - Picked up by the background worker to parse elements into the EAV schema.
*/
CREATE TABLE [dbo].[ServiceResponseIndexingStatus] (
    -- Primary Key & Foreign Key pointing directly to the ServiceResponseFiles record.
    [ServiceResponseFileId] INT NOT NULL,
    -- Processing status state ('Pending', 'Processing', 'Completed', 'Failed').
    [IndexingStatus] VARCHAR(20) NOT NULL CONSTRAINT [DF_ServiceResponseIndexingStatus_Status] DEFAULT 'Pending',
    -- Error message and stack trace detailing failure if IndexingStatus = 'Failed'.
    [IndexingFailureReason] NVARCHAR(MAX) NULL,
    -- Timestamp when background parsing successfully completed.
    [LastIndexedAt] DATETIME NULL,
    -- Timestamp when the status tracking entry was created.
    [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_ServiceResponseIndexingStatus_CreatedAt] DEFAULT GETDATE(),

    CONSTRAINT [PK_ServiceResponseIndexingStatus] PRIMARY KEY CLUSTERED ([ServiceResponseFileId] ASC),
    CONSTRAINT [CK_ServiceResponseIndexingStatus_Status] CHECK ([IndexingStatus] IN ('Pending', 'Processing', 'Completed', 'Failed')),
    CONSTRAINT [FK_ServiceResponseIndexingStatus_ServiceResponseFiles] FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
);
GO

-- Filtered queue index enabling the background worker to fetch unindexed response files efficiently.
CREATE NONCLUSTERED INDEX [IX_ServiceResponseIndexingStatus_Pending] 
ON [dbo].[ServiceResponseIndexingStatus] ([IndexingStatus] ASC, [CreatedAt] ASC) 
WHERE [IndexingStatus] IN ('Pending', 'Failed');
GO