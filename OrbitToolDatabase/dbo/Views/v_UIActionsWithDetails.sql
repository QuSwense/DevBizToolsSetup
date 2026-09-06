-- UI actions with page and permission details
CREATE VIEW [dbo].[v_UIActionsWithDetails]
AS
SELECT
    ua.Id,
    ua.PublicId,
    ua.PageId,
    ua.ActionName,
    ua.DisplayName,
    ua.ResourcePermissionsId,
    ua.ActionType,
    ua.UiElementId,
    ua.IsActive,
    ua.CreatedAt,
    ua.CreatedBy,
    ua.LastUpdatedAt,
    ua.LastUpdatedBy,
    -- Page details
    up.Name AS PageName,
    up.PublicId AS PagePublicId,
    up.IsVisibleInNav AS PageIsVisibleInNav,
    -- Required permission details
    rp.PermissionKey AS RequiredPermissionKey,
    rp.PublicId AS RequiredPermissionPublicId,
    -- Human-readable action type description
    CASE ua.ActionType
        WHEN 'Button' THEN 'Clickable button control'
        WHEN 'Link' THEN 'Hyperlink navigation'
        WHEN 'Menu' THEN 'Menu item action'
        WHEN 'Tab' THEN 'Tab selection'
        WHEN 'Field' THEN 'Form input field'
        WHEN 'Grid' THEN 'Data grid action'
        ELSE 'Other action type'
    END AS ActionTypeDescription,
    -- Status description
    CASE WHEN ua.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS StatusDescription
FROM [dbo].[UIActions] ua
INNER JOIN [dbo].[UIPages] up ON ua.PageId = up.Id
INNER JOIN [dbo].[ResourcePermissions] rp ON ua.ResourcePermissionsId = rp.Id;
GO
