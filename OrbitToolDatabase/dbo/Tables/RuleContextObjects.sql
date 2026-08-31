/*
    Table: RuleContextObjects
    Description: This table stores the context objects for rules, including their names, associated rule types, and descriptions.
    Logic: Each context object is linked to a specific rule type, which is defined by its assembly-qualified name. The table ensures that each context name is unique and provides an active status for managing the lifecycle of context objects.
*/
CREATE TABLE [dbo].[RuleContextObjects] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Context Name, must be unique
    [ContextName] NVARCHAR(100) NOT NULL UNIQUE,  -- e.g., "Customer", "Order", "Product"
    -- Rule Type Identifier, linking to the specific rule type in .NET
    [RuleTypeId] NVARCHAR(255) NOT NULL,         -- Full assembly-qualified type name
    -- Optional Description of the Context Object
    [Description] NVARCHAR(500) NULL,
    -- Active Status of the Context Object
    [IsActive] BIT DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedDate] DATETIME DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedDate] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_RuleContextObjects PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UIX_RuleContextObjects_ContextName UNIQUE ([ContextName] ASC),
    
    CONSTRAINT FK_RuleContextObjects_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RuleContextObjects_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
