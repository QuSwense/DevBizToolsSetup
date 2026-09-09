namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the types of UI action elements available on pages.
/// Maps to UIActions.ActionType: 'Button', 'MenuItem', 'Tab', 'Link'.
/// </summary>
public enum EUiActionType
{
    /// <summary>A button element.</summary>
    Button = 0,

    /// <summary>A menu item element.</summary>
    MenuItem = 1,

    /// <summary>A tab element.</summary>
    Tab = 2,

    /// <summary>A hyperlink element.</summary>
    Link = 3
}
