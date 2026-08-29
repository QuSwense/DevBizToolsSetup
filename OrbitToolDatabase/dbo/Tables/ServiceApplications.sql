CREATE TABLE [dbo].[ServiceApplications] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceType] VARCHAR(10) NOT NULL,
    [ServiceAppAuthenticationId] INT NULL,
    [AppName] NVARCHAR(200) NOT NULL,
    [BaseUrl] NVARCHAR(500) NOT NULL,
    [DefinitionType] VARCHAR(20) NULL, -- 'WSDL', 'Swagger', 'OpenAPI'
    [DefinitionRelativeUrl] NVARCHAR(250) NULL,
    [HealthcheckRelativeUrl] NVARCHAR(250) NULL,
    [Description] NVARCHAR(MAX) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceApplications_IsActive DEFAULT 1,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceApplications_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceApplications_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceApplications PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceApplications_AppName UNIQUE ([AppName] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceApplications_ServiceType
        CHECK ([ServiceType] IN ('SOAP', 'REST')),
    CONSTRAINT CK_ServiceApplications_BaseUrl
        CHECK (LEFT([BaseUrl], 7) = 'http://' OR LEFT([BaseUrl], 8) = 'https://'),
    CONSTRAINT CK_ServiceApplications_DefinitionType
        CHECK ([DefinitionType] IS NULL OR [DefinitionType] IN ('WSDL', 'Swagger', 'OpenAPI')),
    CONSTRAINT CK_ServiceApplications_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceApplications_ServiceAppAuthentications_AuthenticationId
        FOREIGN KEY ([ServiceAppAuthenticationId]) REFERENCES [dbo].[ServiceAppAuthentications]([Id]) ON DELETE SET NULL,
    CONSTRAINT FK_ServiceApplications_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceApplications_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
