CREATE TABLE [dbo].[ServiceAppPermissions] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceApplicationId] INT NOT NULL,
    [SharedWithUserId] NVARCHAR(20) NOT NULL,
    [AccessLevel] VARCHAR(20) NOT NULL
        CONSTRAINT [DF_ServiceAppPermissions_AccessLevel] DEFAULT 'Read',
    [GrantedAt] DATETIME NOT NULL
        CONSTRAINT [DF_ServiceAppPermissions_GrantedAt] DEFAULT GETDATE(),
    [GrantedBy] NVARCHAR(20) NOT NULL,

    -- Primary Key
    CONSTRAINT [PK_ServiceAppPermissions] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CK_ServiceAppPermissions_AccessLevel]
        CHECK ([AccessLevel] IN ('Read', 'Write', 'Execute')),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceAppPermissions_ServiceApplications_ServiceApplicationId]
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceAppPermissions_Users_SharedWithUserId]
        FOREIGN KEY ([SharedWithUserId]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_ServiceAppPermissions_Users_GrantedBy]
        FOREIGN KEY ([GrantedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ServiceAppPermissions_ServiceApplicationId_SharedWithUserId]
    ON [dbo].[ServiceAppPermissions]([ServiceApplicationId] ASC, [SharedWithUserId] ASC)
