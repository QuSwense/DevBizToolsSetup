/*
    Table: DirectExecutionGroupServiceRequestFileLinks
    Description: Stores links between direct execution groups and service request files, including their metadata for auditing purposes.
    Logic:
    - The table should store various links between direct execution groups and service request files with their respective details.
*/
CREATE TABLE [dbo].[DirectExecutionGroupServiceRequestFileLinks] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinks_PublicId DEFAULT NEWID(),
    -- Foreign key to DirectExecutionGroups
    [DirectExecutionGroupId] INT NOT NULL,
    -- Foreign key to ServiceRequestFiles
    [ServiceRequestFileId] INT NOT NULL,
    -- Execution order within the audit
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinks_ExecutionOrder DEFAULT 0,
    -- Indicates if the link record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinks_IsActive DEFAULT 1,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinks_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_DirectExecutionGroupServiceRequestFileLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_DirectExecutionGroupServiceRequestFileLinks_PublicId_RecordVersion UNIQUE ([PublicId] ASC, [RecordVersion] ASC),

    -- Check constraints
    CONSTRAINT CK_DirectExecutionGroupServiceRequestFileLinks_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinks_DirectExecutionGroups_DirectExecutionGroupId
        FOREIGN KEY ([DirectExecutionGroupId]) REFERENCES [dbo].[DirectExecutionGroups]([Id]),
    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinks_ServiceRequestFiles_ServiceRequestFileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO