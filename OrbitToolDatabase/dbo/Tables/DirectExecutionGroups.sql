/*
    Table: DirectExecutionGroups
    Description: Stores information about direct execution groups, including their metadata for auditing purposes.
    Logic:
    - The table should store various direct execution groups with their respective details.
*/
CREATE TABLE [dbo].[DirectExecutionGroups] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_DirectExecutionGroups_PublicId DEFAULT NEWID(),
    -- Name of the direct execution group
    [Name] NVARCHAR(200) NOT NULL,
    -- Indicates if the direct execution group record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_DirectExecutionGroups_IsActive DEFAULT 1,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_DirectExecutionGroups_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_DirectExecutionGroups_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_DirectExecutionGroups PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_DirectExecutionGroups_PublicId_RecordVersion UNIQUE ([PublicId] ASC, [RecordVersion] ASC),

    -- Check constraints
    CONSTRAINT CK_DirectExecutionGroups_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_DirectExecutionGroups_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO