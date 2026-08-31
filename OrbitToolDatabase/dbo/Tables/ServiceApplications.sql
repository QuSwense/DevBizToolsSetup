/* 
    Table: ServiceApplications
    Description: Stores information about service applications, including their type, authentication details, URLs, and metadata for auditing purposes.
    Logic:
    - The table should store various service applications with their respective details.
    - If we have to update the service application details, we will create a new record by default unless forced by the Admin in UI. We will not mark the existing record as inactive. The old records might still be referred by existing service applications.
*/
CREATE TABLE [dbo].[ServiceApplications] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceApplications_PublicId DEFAULT NEWID(),
    -- Type of service application, e.g., 'SOAP', 'REST'
    [ServiceType] VARCHAR(10) NOT NULL,
    -- Foreign Key to ServiceAppAuthentications table
    [ServiceAppAuthenticationId] BIGINT NULL,
    -- Name of the service application, e.g., 'My SOAP Service', 'My REST API'
    [Name] NVARCHAR(200) NOT NULL,
    -- Base URL of the service application, e.g., 'https://api.example.com', 'http://service.example.com'
    [BaseUrl] NVARCHAR(500) NOT NULL,
    -- Type of definition used for the service application, e.g., 'WSDL', 'Swagger', 'OpenAPI'
    [DefinitionType] VARCHAR(20) NULL, -- 'WSDL', 'Swagger', 'OpenAPI'
    -- Relative URL to the definition file for the service application, e.g., '/api/swagger.json', '/service.wsdl'
    [DefinitionRelativeUrl] NVARCHAR(250) NULL,
    -- Relative URL to the health check endpoint for the service application, e.g., '/health', '/status'
    [HealthcheckRelativeUrl] NVARCHAR(250) NULL,
    -- Optional description of the service application, providing additional context or information about its purpose and functionality
    [Description] NVARCHAR(MAX) NULL,
    -- Indicates if the service application record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceApplications_IsActive DEFAULT 1,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceApplications_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceApplications_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceApplications PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceApplications_Name UNIQUE ([Name] ASC, [RecordVersion] ASC),
    CONSTRAINT UQ_ServiceApplications_PublicId UNIQUE ([PublicId] ASC, [RecordVersion] ASC),

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
    CONSTRAINT FK_ServiceApplications_ServiceAppAuthentications_ServiceAppAuthenticationId
        FOREIGN KEY ([ServiceAppAuthenticationId]) REFERENCES [dbo].[ServiceAppAuthentications]([Id]) ON DELETE SET NULL,
    CONSTRAINT FK_ServiceApplications_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceApplications_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
