-- ============================================================================
-- Service Metadata Architecture (Unified REST & SOAP Schema)
-- ============================================================================
USE [OrbitTool];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ServiceAppAuthentications Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceAppAuthentications' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceAppAuthentications] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AuthenticationType] VARCHAR(50) NOT NULL,
        [EncryptionAlgorithmType] VARCHAR(50) NULL, -- e.g., 'AES', 'RSA', 'None'
        [EncryptedCredentialsJson] NVARCHAR(MAX) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceAppAuthentication_IsActive DEFAULT 1,
        [RecordVersion] VARCHAR(50) NOT NULL 
            CONSTRAINT DF_ServiceAppAuthentications_RecordVersion DEFAULT (dbo.[fn_CalculateVersion](NULL)),
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceAppAuthentication_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_ServiceAppAuthentications PRIMARY KEY CLUSTERED ([Id] ASC),

        -- Check constraints
        CONSTRAINT CK_ServiceAppAuthentications_Type 
            CHECK ([AuthenticationType] IN ('Basic', 'NTLM', 'APIKey', 'OAuth2', 'Bearer', 'Custom')),
        CONSTRAINT CK_ServiceAppAuthentications_EncryptionAlgorithmType 
            CHECK ([EncryptionAlgorithmType] IS NULL OR [EncryptionAlgorithmType] IN ('AES-GCM', 'RSA', 'None')),
        CONSTRAINT CK_ServiceAppAuthentications_EncryptedCredentialsJson
            CHECK (ISJSON([EncryptedCredentialsJson]) = 1),
        CONSTRAINT CK_ServiceAppAuthentications_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        -- Foreign keys
        CONSTRAINT FK_ServiceAppAuthentications_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceAppAuthentications_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- Trigger to auto-update Version on update/delete
CREATE TRIGGER [dbo].[trg_ServiceAppAuthentications_AutoUpdate]
ON [dbo].[ServiceAppAuthentications]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SAA]
    SET 
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy], 
            [i].[CreatedBy], 
            SYSTEM_USER, 
            'SYSTEM'
        )
    FROM [dbo].[ServiceAppAuthentications] AS [SAA]
    INNER JOIN [inserted] AS [i] ON [SAA].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SAA].[Id] = [d].[Id];
END;
GO

-- ServiceApplications Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceApplications' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceApplications] (
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
            CONSTRAINT DF_ServiceApplications_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
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
            FOREIGN KEY ([ServiceAppAuthenticationId]) REFERENCES dbo.[ServiceAppAuthentications]([Id]) ON DELETE SET NULL,
        CONSTRAINT FK_ServiceApplications_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceApplications_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- Trigger to auto-update Version on update/delete
CREATE TRIGGER [dbo].[trg_ServiceApplications_AutoUpdate]
ON [dbo].[ServiceApplications]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SA]
    SET 
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy], 
            [i].[CreatedBy], 
            SYSTEM_USER, 
            'SYSTEM'
        )
    FROM [dbo].[ServiceApplications] AS [SA]
    INNER JOIN [inserted] AS [i] ON [SA].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SA].[Id] = [d].[Id];
END;
GO

-- ServiceDefinitionSyncs Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceDefinitionSyncs' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceDefinitionSyncs] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceApplicationId] INT NOT NULL,
        [DefinitionUrl] NVARCHAR(500) NULL, -- Built from BaseUrl + DefinitionRelativeUrl
        [DefinitionContent] VARBINARY(MAX) NOT NULL, -- compressed content of the definition file (WSDL, Swagger, OpenAPI)
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL, -- e.g., 'Zstandard', 'deflate', 'none'
        [FileHash] VARCHAR(64) NULL,
        [RecordVersion] VARCHAR(50) NOT NULL
            CONSTRAINT DF_ServiceDefinitionSyncs_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
        [SyncedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceDefinitionSync_SyncedAt DEFAULT GETDATE(),
        [SyncedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceDefinitionSyncs PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceDefinitionSyncs_DefinitionUrl 
            CHECK (LEFT([DefinitionUrl], 7) = 'http://' OR LEFT([DefinitionUrl], 8) = 'https://'),
        CONSTRAINT CK_ServiceDefinitionSyncs_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceDefinitionSyncs_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
        CONSTRAINT CK_ServiceDefinitionSyncs_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        -- Foreign keys
        CONSTRAINT FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId 
            FOREIGN KEY ([ServiceApplicationId]) REFERENCES dbo.[ServiceApplications]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceDefinitionSyncs_Users_SyncedBy 
            FOREIGN KEY ([SyncedBy]) REFERENCES dbo.[Users]([UserId]),

        -- Index constraint
        CONSTRAINT IX_ServiceDefinitionSyncs_ServiceApplicationId UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC)
    );
END
GO

-- ServiceDefinitionSyncHistorys Table (only by trigger)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceDefinitionSyncHistorys' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceDefinitionSyncHistorys] (
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [ServiceDefinitionSyncId] INT NOT NULL,
        [ServiceApplicationId] INT NOT NULL,
        [DefinitionUrl] NVARCHAR(500) NULL,
        [DefinitionContent] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [RecordVersion] VARCHAR(50) NOT NULL,
        [SyncedAt] DATETIME NOT NULL,
        [SyncedBy] NVARCHAR(20) NOT NULL,
        [ChangedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceDefinitionSyncHistorys_ChangedAt DEFAULT GETDATE(),
        [ChangedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceDefinitionSyncHistorys PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceDefinitionSyncHistorys_DefinitionUrl 
            CHECK (LEFT([DefinitionUrl], 7) = 'http://' OR LEFT([DefinitionUrl], 8) = 'https://'),
        CONSTRAINT CK_ServiceDefinitionSyncs_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceDefinitionSyncs_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
        CONSTRAINT CK_ServiceDefinitionSyncs_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        -- Foreign keys
        CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceApplications_ServiceApplicationId 
            FOREIGN KEY ([ServiceApplicationId]) REFERENCES dbo.[ServiceApplications]([Id]),
        CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceDefinitionSyncs_ServiceDefinitionSyncId 
            FOREIGN KEY ([ServiceDefinitionSyncId]) REFERENCES dbo.[ServiceDefinitionSyncs]([Id]),
        CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_SyncedBy 
            FOREIGN KEY ([SyncedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_ChangedBy 
            FOREIGN KEY ([ChangedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- Trigger to auto-update Version and audit updates
CREATE TRIGGER [dbo].[trg_ServiceDefinitionSyncs_AutoUpdate]
ON [dbo].[ServiceDefinitionSyncs]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the row with new version + timestamp
    UPDATE [SDS]
    SET
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [SyncedAt] = GETDATE()
    FROM [dbo].[ServiceDefinitionSyncs] AS [SDS]
    INNER JOIN [inserted] AS [i] ON [SDS].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SDS].[Id] = [d].[Id];

    -- Audit the change into history table
    INSERT INTO [dbo].[ServiceDefinitionSyncHistorys] (
        [ServiceDefinitionSyncId],
        [ServiceApplicationId],
        [DefinitionUrl],
        [DefinitionContent],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [FileHash],
        [RecordVersion],
        [SyncedAt],
        [SyncedBy],
        [ChangedAt],
        [ChangedBy]
    )
    SELECT
        [d].[Id],                        -- base table Id
        [d].[ServiceApplicationId],
        [d].[DefinitionUrl],
        [d].[DefinitionContent],
        [d].[UncompressedSizeBytes],
        [d].[CompressionAlgorithmType],
        [d].[FileHash],
        [d].[RecordVersion],
        [d].[SyncedAt],
        [d].[SyncedBy],
        GETDATE(),
        COALESCE( -- FIXED: Use COALESCE to handle NULL LastUpdatedBy
            [i].[LastUpdatedBy], 
            [i].[SyncedBy], 
            SYSTEM_USER, 
            'SYSTEM'
        )
    FROM [deleted] AS [d]
    INNER JOIN [inserted] AS [i] ON [d].[Id] = [i].[Id];
END;
GO

-- ServiceOperations Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceOperations' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceOperations] (
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
            CONSTRAINT DF_ServiceOperations_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
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
            FOREIGN KEY ([ServiceApplicationId]) REFERENCES dbo.[ServiceApplications]([Id]),
        CONSTRAINT FK_ServiceOperations_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceOperations_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX IX_ServiceOperations_ServiceApplicationId 
        ON dbo.[ServiceOperations]([ServiceApplicationId] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceOperations_IsActive 
        ON dbo.[ServiceOperations]([IsActive] ASC);
END
GO

-- Trigger to auto-update Version on update/delete
CREATE TRIGGER [dbo].[trg_ServiceOperations_AutoUpdate]
ON [dbo].[ServiceOperations]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- ServiceOperations doesn't have a history table, 
    -- so just update the current record
    UPDATE [SO]
    SET 
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy], 
            [i].[CreatedBy], 
            SYSTEM_USER, 
            'SYSTEM'
        )
    FROM [dbo].[ServiceOperations] AS [SO]
    INNER JOIN [inserted] AS [i] ON [SO].[Id] = [i].[Id]
    INNER JOIN [deleted] AS [d] ON [SO].[Id] = [d].[Id];
END;
GO

-- ServiceRequestFiles Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceRequestFiles' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceRequestFiles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [OperationId] INT NOT NULL,
        [FileFormat] VARCHAR(10) NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [RecordVersion] VARCHAR(50) NOT NULL 
            CONSTRAINT DF_ServiceRequestFiles_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
        [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFiles_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFiles_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_ServiceRequestFiles PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceRequestFiles_Format 
            CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT CK_ServiceRequestFiles_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceRequestFiles_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
        CONSTRAINT CK_ServiceRequestFiles_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        -- Foreign keys
        CONSTRAINT FK_ServiceRequestFiles_ServiceOperations_OperationId 
            FOREIGN KEY ([OperationId]) REFERENCES dbo.[ServiceOperations]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceRequestFiles_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceRequestFiles_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_OperationId 
        ON dbo.[ServiceRequestFiles]([OperationId] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_CreatedAt 
        ON dbo.[ServiceRequestFiles]([CreatedAt] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_FileName 
        ON dbo.[ServiceRequestFiles]([FileName] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_IsActive 
        ON dbo.[ServiceRequestFiles]([IsActive] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_CreatedBy 
        ON dbo.[ServiceRequestFiles]([CreatedBy] ASC);
END
GO

-- ServiceRequestFileHistorys Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceRequestFileHistorys' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceRequestFileHistorys] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceRequestFileId] INT NOT NULL,
        [FileFormat] VARCHAR(10) NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [RecordVersion] VARCHAR(50) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFileHistorys_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_ServiceRequestFileHistorys PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceRequestFileHistorys_FileFormat 
            CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT CK_ServiceRequestFileHistorys_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceRequestFileHistorys_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
        CONSTRAINT CK_ServiceRequestFileHistorys_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        -- Foreign keys
        CONSTRAINT FK_ServiceRequestFileHistorys_ServiceRequestFiles_ServiceRequestFileId
            FOREIGN KEY ([ServiceRequestFileId]) REFERENCES dbo.[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceRequestFileHistorys_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceRequestFileHistorys_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_ServiceRequestFileId 
        ON dbo.[ServiceRequestFileHistorys]([ServiceRequestFileId] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_CreatedAt 
        ON dbo.[ServiceRequestFileHistorys]([CreatedAt] ASC);
    CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_CreatedBy 
        ON dbo.[ServiceRequestFileHistorys]([CreatedBy] ASC);
END
GO

-- Trigger to auto-update RecordVersion and insert audit history
CREATE TRIGGER [dbo].[trg_ServiceRequestFiles_Audit]
ON [dbo].[ServiceRequestFiles]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the main table with LastUpdatedAt
    UPDATE [SRF]
    SET 
        [RecordVersion] = [dbo].[fn_CalculateVersion]([d].[RecordVersion]),
        [LastUpdatedAt] = GETDATE(),
        [LastUpdatedBy] = COALESCE(
            [i].[LastUpdatedBy], 
            [i].[CreatedBy], 
            SYSTEM_USER, 
            'SYSTEM'
        )
    FROM [dbo].[ServiceRequestFiles] AS [SRF]
    INNER JOIN [inserted] AS [i] ON [SRF].[Id] = [i].[Id];

    -- Insert audit history (the OLD values from deleted)
    INSERT INTO [dbo].[ServiceRequestFileHistorys] (
        [ServiceRequestFileId],
        [FileFormat],
        [FileName],
        [FileData],
        [UncompressedSizeBytes],
        [CompressionAlgorithmType],
        [FileHash],
        [CreatedAt],
        [CreatedBy],
        [LastUpdatedAt],
        [LastUpdatedBy]
    )
    SELECT
        [d].[Id], -- Main table Id becomes ServiceRequestFileId in history
        [d].[FileFormat],
        [d].[FileName],
        [d].[FileData],
        [d].[UncompressedSizeBytes],
        [d].[CompressionAlgorithmType],
        [d].[FileHash],
        [d].[CreatedAt],
        [d].[CreatedBy],
        GETDATE(), -- LastUpdatedAt in history = when change happened
        [i].[LastUpdatedBy] -- Who made the change
    FROM [deleted] AS [d]
    INNER JOIN [inserted] AS [i] ON [d].[Id] = [i].[Id];
END;
GO

-- ServiceRequestFileEmbeddings Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceRequestFileEmbeddings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE [dbo].[ServiceRequestFileEmbeddings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceRequestFileId] INT NULL,
        [ServiceRequestFileHistoryId] INT NULL,
        [FileFormat] VARCHAR(10) NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL 
            CONSTRAINT DF_ServiceRequestFileEmbeddings_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_ServiceRequestFileEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceRequestFileEmbeddings_OneParent 
            CHECK (
                ([ServiceRequestFileId] IS NOT NULL AND [ServiceRequestFileHistoryId] IS NULL)
                OR ([ServiceRequestFileId] IS NULL AND [ServiceRequestFileHistoryId] IS NOT NULL)
            ),
        CONSTRAINT CK_ServiceRequestFileEmbeddings_Format 
            CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT CK_ServiceRequestFileEmbeddings_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceRequestFileEmbeddings_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

        CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFiles 
            FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFileHistorys 
            FOREIGN KEY ([ServiceRequestFileHistoryId]) REFERENCES [dbo].[ServiceRequestFileHistorys]([Id]) ON DELETE CASCADE
    );
END
GO

-- Updated ServiceResponseFiles Table (without RecordVersion and IsActive)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceResponseFiles' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceResponseFiles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FileFormat] VARCHAR(10) NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL 
            CONSTRAINT DF_ServiceResponseFiles_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceResponseFiles PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceResponseFiles_Format 
            CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT CK_ServiceResponseFiles_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceResponseFiles_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

        -- Foreign Key Constraint
        CONSTRAINT FK_ServiceResponseFiles_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- ServiceResponseFileEmbeddings Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceResponseFileEmbeddings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE [dbo].[ServiceResponseFileEmbeddings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceResponseFileId] INT NOT NULL,
        [FileFormat] VARCHAR(10) NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [CompressionAlgorithmType] VARCHAR(50) NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL 
            CONSTRAINT [DF_ServiceResponseFileEmbeddings_CreatedAt] DEFAULT GETDATE(),

        CONSTRAINT [PK_ServiceResponseFileEmbeddings] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceResponseFileEmbeddings_FileFormat 
            CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT CK_ServiceResponseFileEmbeddings_CompressionAlgorithmType 
            CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
        CONSTRAINT CK_ServiceResponseFileEmbeddings_FileHash 
            CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

        -- Foreign Key
        CONSTRAINT [FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId] 
            FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_ServiceResponseFileId] 
        ON [dbo].[ServiceResponseFileEmbeddings]([ServiceResponseFileId] ASC);
    CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_FileName] 
        ON [dbo].[ServiceResponseFileEmbeddings]([FileName] ASC);
    CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_FileFormat] 
        ON [dbo].[ServiceResponseFileEmbeddings]([FileFormat] ASC);
END
GO

-- ServiceOperationSchemas Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceOperationSchemas' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE [dbo].[ServiceOperationSchemas] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [DefinitionSyncId] INT NOT NULL,
        [OperationId] INT NULL,
        [TargetNamespace] NVARCHAR(500) NULL,
        [SchemaContent] NVARCHAR(MAX) NOT NULL,
        [CreatedAt] DATETIME NOT NULL 
            CONSTRAINT [DF_ServiceOperationSchemas_CreatedAt] DEFAULT GETDATE(),

        -- Primary Key
        CONSTRAINT [PK_ServiceOperationSchemas] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_ServiceOperationSchemas_TargetNamespace 
            CHECK ([TargetNamespace] IS NULL OR LEFT([TargetNamespace], 7) = 'http://' OR LEFT([TargetNamespace], 8) = 'https://'),
        -- Check schema content is xml
        CONSTRAINT CK_ServiceOperationSchemas_SchemaContent 
            CHECK (TRY_CAST([SchemaContent] AS XML) IS NOT NULL),

        -- Foreign Keys - FIXED: Reference to ServiceDefinitionSyncs (plural)
        CONSTRAINT [FK_ServiceOperationSchemas_ServiceDefinitionSync_DefinitionSyncId] 
            FOREIGN KEY ([DefinitionSyncId]) 
            REFERENCES [dbo].[ServiceDefinitionSyncs]([Id]) ON DELETE CASCADE, -- Fixed table name
        CONSTRAINT [FK_ServiceOperationSchemas_ServiceOperations_OperationId] 
            FOREIGN KEY ([OperationId]) 
            REFERENCES [dbo].[ServiceOperations]([Id])
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_DefinitionSyncId] 
        ON [dbo].[ServiceOperationSchemas]([DefinitionSyncId] ASC);
    CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_OperationId] 
        ON [dbo].[ServiceOperationSchemas]([OperationId] ASC);
END
GO

-- ServiceAppPermissions Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceAppPermissions' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
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
    );

    -- Indexes
    CREATE UNIQUE NONCLUSTERED INDEX [IX_ServiceAppPermissions_ServiceApplicationId_SharedWithUserId] 
        ON [dbo].[ServiceAppPermissions]([ServiceApplicationId] ASC, [SharedWithUserId] ASC);
END
GO

-- SoapNamespaces Table (merged definition)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapNamespaces' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE [dbo].[SoapNamespaces] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceOperationSchemaId] INT NOT NULL,
        [Prefix] NVARCHAR(50) NOT NULL,
        [NamespaceUri] NVARCHAR(500) NOT NULL,
        [CreatedAt] DATETIME NOT NULL 
            CONSTRAINT [DF_SoapNamespaces_CreatedAt] DEFAULT GETDATE(),

        -- Primary Key
        CONSTRAINT [PK_SoapNamespaces] PRIMARY KEY CLUSTERED ([Id] ASC),

        -- Foreign Keys
        CONSTRAINT [FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId] 
            FOREIGN KEY ([ServiceOperationSchemaId]) REFERENCES [dbo].[ServiceOperationSchemas]([Id]) ON DELETE CASCADE
    );

    -- Indexes
    CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_ServiceOperationSchemaId] 
        ON [dbo].[SoapNamespaces]([ServiceOperationSchemaId] ASC);
    CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_Prefix] 
        ON [dbo].[SoapNamespaces]([Prefix] ASC);
    CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_NamespaceUri] 
        ON [dbo].[SoapNamespaces]([NamespaceUri] ASC);
END
GO

-- DirectExecutionAudit Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'DirectExecutionAudits' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[DirectExecutionAudit] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_DirectExecutionAudit_ExecutedAt DEFAULT GETDATE(),
        [ExecutionCompletedAt] DATETIME NULL,
        [ExecutionStatus] NVARCHAR(50) NOT NULL,
        [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
        [ExecutedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_DirectExecutionAudit PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_DirectExecutionAudit_Users_ExecutedBy 
            FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.[Users]([UserId]),
    );
END
GO

-- DirectExecutionAuditResponseFileLinks Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'DirectExecutionAuditResponseFileLinks' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[DirectExecutionAuditResponseFileLinks] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [DirectExecutionAuditId] INT NOT NULL,
        [ServiceRequestFileId] INT NOT NULL,
        [ServiceResponseFileId] INT NOT NULL,
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_DirectExecutionAudit_ExecutedAt DEFAULT GETDATE(),
        [ExecutionCompletedAt] DATETIME NULL,
        [HttpStatusCode] INT NULL, -- Response status code (200, 404, 500, etc.)
        [HttpVersion] NVARCHAR(10) NULL, -- HTTP/1.1, HTTP/2, HTTP/3
        [HttpRequestDurationMs] INT NULL, -- Total request duration in milliseconds
        [HttpRequestHeaders] NVARCHAR(MAX) NULL, -- JSON of request headers
        [HttpResponseHeaders] NVARCHAR(MAX) NULL, -- JSON of response headers
        [HttpContentType] NVARCHAR(255) NULL, -- Content-Type from response
        [HttpContentLength] BIGINT NULL, -- Response content length in bytes
        [ExecutionStatus] NVARCHAR(50) NOT NULL,
        [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution like ErrorTYpe, ErrorMessage, StackTrace, etc.
        [ExecutedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_DirectExecutionAuditResponseFileLinks PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_DirectExecutionAudit_DirectExecutionAuditId
            FOREIGN KEY ([DirectExecutionAuditId]) REFERENCES dbo.[DirectExecutionAudit]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceRequestFiles_ServiceRequestFileId
            FOREIGN KEY ([ServiceRequestFileId]) REFERENCES dbo.[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceResponseFiles_ServiceResponseFileId
            FOREIGN KEY ([ServiceResponseFileId]) REFERENCES dbo.[ServiceResponseFiles]([Id]) ON DELETE CASCADE
    );
END
GO