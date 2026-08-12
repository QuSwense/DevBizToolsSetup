CREATE TABLE [dbo].[Languages] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [CultureCode]     NVARCHAR(10) NOT NULL,
    [DisplayName]     NVARCHAR(100) NOT NULL,
    [IsDefault]       BIT NOT NULL DEFAULT 0,
    [IsActive]        BIT NOT NULL DEFAULT 1
    
    CONSTRAINT [UX_Languages_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_Languages_CultureCode] 
        UNIQUE ([CultureCode])
);

GO