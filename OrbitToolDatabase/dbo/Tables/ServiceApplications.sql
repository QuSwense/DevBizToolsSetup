/* 
    Table: ServiceApplications
    Description: Stores information about service applications which relates to the name in appsettings.json
    Logic:
    - The table should store various service applications with their respective details.
    - Update is only done in the appsettings.json file.
*/
CREATE TABLE [dbo].[ServiceApplications] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Name of the service application, e.g., 'My SOAP Service', 'My REST API'
    [Name] NVARCHAR(200) NOT NULL,
    -- Optional description of the service application, providing additional context or information about its purpose and functionality
    [Description] NVARCHAR(MAX) NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceApplications_CreatedAt DEFAULT GETDATE(),

    CONSTRAINT PK_ServiceApplications PRIMARY KEY CLUSTERED ([Id] ASC),

    -- Foreign keys
    CONSTRAINT FK_ServiceApplications_ServiceAppAuthentications_ServiceAppAuthenticationId
        FOREIGN KEY ([ServiceAppAuthenticationId]) REFERENCES [dbo].[ServiceAppAuthentications]([Id]) ON DELETE SET NULL
);
GO