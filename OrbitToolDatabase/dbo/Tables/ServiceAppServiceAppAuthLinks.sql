/*
    Table: ServiceAppServiceAppAuthLinks
    Description: Links service applications to their authentication configurations.
    Logic:
    - This table establishes a many-to-many relationship between service applications and their authentication configurations.
    - Each service application can have multiple authentication configurations, and each authentication configuration can be used by multiple service applications.
    - e.g., a service application might have both 'Basic' and 'OAuth2' authentication configurations linked to it. Also, may have database authentication linked as well.
*/
CREATE TABLE [dbo].[ServiceAppServiceAppAuthLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceAppId] INT NOT NULL,
    [ServiceAppAuthenticationId] INT NOT NULL,
    CONSTRAINT PK_ServiceAppServiceAppAuthLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceAppServiceAppAuthLinks_ServiceApp_ServiceAppId
        FOREIGN KEY ([ServiceAppId]) REFERENCES [dbo].[ServiceApp]([Id]),
    CONSTRAINT FK_ServiceAppServiceAppAuthLinks_ServiceAppAuthentications_ServiceAppAuthenticationId
        FOREIGN KEY ([ServiceAppAuthenticationId]) REFERENCES [dbo].[ServiceAppAuthentications]([Id])
);
GO