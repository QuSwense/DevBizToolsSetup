namespace OrbitHub.Ui.Models;

/// <summary>
/// Represents a single item in a menu group (used in the Monaco Editor action menu).
/// </summary>
public class MenuItem
{
    /// <summary>
    /// Unique identifier for the menu item.
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// Display label shown in the menu.
    /// </summary>
    public string Label { get; set; } = string.Empty;

    /// <summary>
    /// Optional keyboard shortcut hint (e.g. "Ctrl+S").
    /// </summary>
    public string? Shortcut { get; set; }

    /// <summary>
    /// Optional Bootstrap icon class (e.g. "bi bi-save").
    /// </summary>
    public string? Icon { get; set; }

    /// <summary>
    /// Whether the item is enabled. Default true.
    /// </summary>
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Whether this item renders as a separator line.
    /// </summary>
    public bool IsSeparator { get; set; }
}

/// <summary>
/// Represents a group of related menu items (used in the Monaco Editor action menu).
/// </summary>
public class MenuGroup
{
    /// <summary>
    /// Group title displayed as a header.
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// Items in this group.
    /// </summary>
    public List<MenuItem> Items { get; set; } = [];
}