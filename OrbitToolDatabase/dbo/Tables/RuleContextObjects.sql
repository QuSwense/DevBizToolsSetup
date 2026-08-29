CREATE TABLE [dbo].[RuleContextObjects] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ContextName] NVARCHAR(100) NOT NULL UNIQUE,  -- e.g., "Customer", "Order", "Product"
    [RuleTypeId] NVARCHAR(255) NOT NULL,         -- Full assembly-qualified type name
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT DEFAULT 1,
    [CreatedDate] DATETIME DEFAULT GETDATE(),

    CONSTRAINT PK_RuleContextObjects PRIMARY KEY CLUSTERED ([Id] ASC)
)
