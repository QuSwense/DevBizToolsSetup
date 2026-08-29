CREATE TABLE [dbo].[ServiceOperations] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceApplicationId] INT NOT NULL,
    [OperationName] NVARCHAR(200) NOT NULL,  -- Soap operation name or REST endpoint name
    [EndpointOrAction] NVARCHAR(500) NULL,
    [HttpMethod] VARCHAR(10) NULL,
    [InputRootElementName] NVARCHAR(200) NULL,
    [OutputRootElementName] NVARCHAR(200) NULL,
    [Description] NVARCHAR(MAX) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceOperations_IsActive DEFAULT 1,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceOperations_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceOperations_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceOperations PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceOperations_HttpMethod
        CHECK ([HttpMethod] IS NULL OR [HttpMethod] IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')),
    CONSTRAINT CK_ServiceOperations_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceOperations_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceOperations_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceOperations_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_ServiceOperations_ServiceApplicationId
    ON [dbo].[ServiceOperations]([ServiceApplicationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceOperations_IsActive
    ON [dbo].[ServiceOperations]([IsActive] ASC)
