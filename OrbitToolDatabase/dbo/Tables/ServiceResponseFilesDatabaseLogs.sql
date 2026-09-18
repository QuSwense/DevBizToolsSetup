/*
    Table: ServiceResponseFilesDatabaseLogs
    Description: Logs database interactions for service applications.
    Logic:
    - This table records each database operation performed by service applications.
    - It helps in auditing and troubleshooting database activities related to service applications.
*/
CREATE TABLE [dbo].[ServiceResponseFilesDatabaseLogs] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [ServiceAppServiceAppAuthLinkId] INT NOT NULL,
    [Details] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
    [ExtractedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceResponseFilesDatabaseLogs_ExtractedAt DEFAULT GETDATE(),

    CONSTRAINT PK_ServiceResponseFilesDatabaseLogs PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_ServiceResponseFilesDatabaseLogs_ServiceResponseFile_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFile]([Id]),
    CONSTRAINT FK_ServiceResponseFilesDatabaseLogs_ServiceAppServiceAppAuthLink_ServiceAppServiceAppAuthLinkId
        FOREIGN KEY ([ServiceAppServiceAppAuthLinkId]) REFERENCES [dbo].[ServiceAppServiceAppAuthLinks]([Id])
);
GO