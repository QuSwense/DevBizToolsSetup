SET IDENTITY_INSERT [dbo].[Languages] ON;

MERGE INTO [dbo].[Languages] AS Target
USING (VALUES 
    (1, N'en-US', N'English (US)', 1, 1),
    (2, N'de-DE', N'Deutsch (Deutschland)', 0, 1)
) AS Source ([Id], [CultureCode], [DisplayName], [IsDefault], [IsActive])
ON (Target.[CultureCode] = Source.[CultureCode])
WHEN MATCHED THEN
    UPDATE SET 
        Target.[DisplayName] = Source.[DisplayName],
        Target.[IsDefault]   = Source.[IsDefault],
        Target.[IsActive]    = Source.[IsActive]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [CultureCode], [DisplayName], [IsDefault], [IsActive])
    VALUES (Source.[Id], Source.[CultureCode], Source.[DisplayName], Source.[IsDefault], Source.[IsActive]);

SET IDENTITY_INSERT [dbo].[Languages] OFF;