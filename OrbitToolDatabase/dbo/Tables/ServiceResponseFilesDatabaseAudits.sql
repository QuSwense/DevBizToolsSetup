/*
    Table: ServiceResponseFilesDatabaseAudits
    Description: Logs database interactions for service applications.
    Logic:
    - This table records each database operation performed by service applications.
    - It helps in auditing and troubleshooting database activities related to service applications.
*/
CREATE TABLE [dbo].[ServiceResponseFilesDatabaseAudits] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] BIGINT NOT NULL,
    [AutheticationName] NVARCHAR(200) NOT NULL,
    [Details] NVARCHAR(MAX) NULL, -- JSON or log details about the execution
    [ExtractedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceResponseFilesDatabaseAudits_ExtractedAt DEFAULT GETDATE(),

    CONSTRAINT PK_ServiceResponseFilesDatabaseAudits PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_ServiceResponseFilesDatabaseAudits_ServiceResponseFile_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id])
);
GO