/* 
    Table: ServiceAppAuthentications
    Description: Stores authentication details for service applications, including the type of authentication, encryption algorithm used, and encrypted credentials.
    Logic:
    - The table should store various authentication configurations
    - If we have to update the authentication details, we will create a new record by default unless forced by the Admin in UI. We will not mark the existing record as inactive. The old records might still be referred by existing service applications.
*/
CREATE TABLE [dbo].[ServiceAppAuthentications] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceAppAuthentications_PublicId DEFAULT NEWID(),
    -- Name of the authentication configuration, e.g., 'My Basic Auth', 'My OAuth2 Config'
    [Name] NVARCHAR(200) NOT NULL,
    -- Type of authentication used for the service application, e.g., 'Basic', 'NTLM', 'APIKey', 'OAuth2', 'Bearer', 'Custom'
    [AuthenticationType] VARCHAR(50) NOT NULL,
    -- Optional encryption algorithm used for encrypting the credentials, e.g., 'AES-GCM', 'RSA', 'None'
    [EncryptionAlgorithmType] VARCHAR(50) NULL,
    -- Encrypted credentials stored as a JSON string, containing necessary authentication details such as username, password, API key, token, etc.
    [EncryptedJson] NVARCHAR(MAX) NOT NULL,
    -- Indicates if the authentication record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceAppAuthentications_IsActive DEFAULT 1,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceAppAuthentications_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceAppAuthentications_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceAppAuthentications PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceAppAuthentications_Name UNIQUE ([Name] ASC, [PublicId] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceAppAuthentications_Type
        CHECK ([AuthenticationType] IN ('Basic', 'NTLM', 'APIKey', 'OAuth2', 'Bearer', 'Custom')),
    CONSTRAINT CK_ServiceAppAuthentications_EncryptionAlgorithmType
        CHECK ([EncryptionAlgorithmType] IS NULL OR [EncryptionAlgorithmType] IN ('AES-GCM', 'RSA', 'None')),
    CONSTRAINT CK_ServiceAppAuthentications_EncryptedJson
        CHECK (ISJSON([EncryptedJson]) = 1),
    CONSTRAINT CK_ServiceAppAuthentications_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceAppAuthentications_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceAppAuthentications_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
