/*
    Seed PermissionToUIPageMapping - Link permissions to UI pages
    NOTE: ResourcePermissions and UIPages must be seeded BEFORE this script.
    Maps permissions to pages by joining on ResourcePermissionsId (the FK column).
    Every UIPage has a non-null ResourcePermissionsId, so a single JOIN covers all.
*/
INSERT INTO [dbo].[PermissionToUIPageMapping] 
    ([ResourcePermissionId], [UIPageId], [AccessType], [CreatedBy])
SELECT 
    rp.[Id],
    up.[Id],
    CASE 
        WHEN rp.[PermissionKey] LIKE '%:admin' OR rp.[PermissionKey] LIKE '%:full' THEN 'Full'
        WHEN rp.[PermissionKey] LIKE '%:write' OR rp.[PermissionKey] LIKE '%:create' OR rp.[PermissionKey] LIKE '%:edit' THEN 'Edit'
        WHEN rp.[PermissionKey] LIKE '%:read' OR rp.[PermissionKey] LIKE '%:view' THEN 'View'
        ELSE 'View'
    END,
    'SYSTEM'
FROM [dbo].[ResourcePermissions] rp
JOIN [dbo].[UIPages] up 
    ON up.[ResourcePermissionsId] = rp.[Id]
WHERE rp.[PermissionKey] IS NOT NULL
GO