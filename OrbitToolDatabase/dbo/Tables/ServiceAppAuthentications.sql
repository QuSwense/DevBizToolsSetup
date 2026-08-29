CREATE TABLE [dbo].[ServiceAppAuthentications] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [AuthenticationType] VARCHAR(50) NOT NULL,
    [EncryptionAlgorithmType] VARCHAR(50) NULL, -- e.g., 'AES', 'RSA', 'None'
    [EncryptedCredentialsJson] NVARCHAR(MAX) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceAppAuthentication_IsActive DEFAULT 1,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceAppAuthentications_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
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
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceAppAuthentications_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
