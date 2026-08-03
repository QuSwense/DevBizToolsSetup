using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Ui.Components;

/// <summary>
/// Toolbar for the MonacoEditor component with navigation, editor settings, search, and action menu.
/// Every section/button has a show/hide parameter for maximum composability.
/// </summary>
public partial class MonacoEditorToolbar
{
    // ── Navigation & File Info ──
    [Parameter] public bool ShowBackButton { get; set; } = true;
    [Parameter] public bool ShowFileName { get; set; } = true;
    [Parameter] public string FileName { get; set; } = "";
    [Parameter] public string? FilePath { get; set; }
    [Parameter] public string? LanguageBadgeText { get; set; }
    [Parameter] public string? LanguageBadgeClass { get; set; }
    [Parameter] public bool HasUnsavedChanges { get; set; }

    // ── Editor Settings ──
    [Parameter] public bool ShowFontSelector { get; set; } = true;
    [Parameter] public bool ShowWordWrapToggle { get; set; } = true;
    [Parameter] public bool ShowLineNumbersToggle { get; set; } = true;
    [Parameter] public bool ShowThemeSelector { get; set; } = true;
    [Parameter] public bool ShowSearchBox { get; set; } = true;
    [Parameter] public bool ShowCursorPosition { get; set; } = true;
    [Parameter] public bool ShowGoToLine { get; set; } = true;

    // ── Actions ──
    [Parameter] public bool ShowSaveButton { get; set; } = true;
    [Parameter] public bool ShowFormatButton { get; set; } = true;
    [Parameter] public bool ShowValidateButton { get; set; } = true;
    [Parameter] public bool ShowDownloadButton { get; set; } = true;
    [Parameter] public bool ShowCompareButton { get; set; } = true;
    [Parameter] public bool ShowUndoRedo { get; set; } = true;
    [Parameter] public bool ShowPrintButton { get; set; } = true;
    [Parameter] public bool ShowActionMenu { get; set; } = true;

    // ── State ──
    [Parameter] public string FontFamily { get; set; } = "JetBrains Mono";
    [Parameter] public EventCallback<string> OnFontFamilyChanged { get; set; }
    [Parameter] public int FontSize { get; set; } = 11;
    [Parameter] public EventCallback<int> OnFontSizeChanged { get; set; }
    [Parameter] public bool WordWrapEnabled { get; set; } = true;
    [Parameter] public EventCallback<bool> OnWordWrapToggled { get; set; }
    [Parameter] public bool LineNumbersEnabled { get; set; } = true;
    [Parameter] public EventCallback<bool> OnLineNumbersToggled { get; set; }
    [Parameter] public string Theme { get; set; } = "vs-dark";
    [Parameter] public EventCallback<string> OnThemeChanged { get; set; }
    [Parameter] public int CursorLine { get; set; } = 1;
    [Parameter] public int CursorColumn { get; set; } = 1;
    [Parameter] public bool IsSaving { get; set; }

    // ── Available options ──
    [Parameter] public IEnumerable<string> AvailableFontFamilies { get; set; } = new[] { "JetBrains Mono", "Menlo", "Consolas", "Fira Code", "Cascadia Code" };
    [Parameter] public IEnumerable<int> AvailableFontSizes { get; set; } = new[] { 10, 11, 12, 13, 14, 16, 18, 20, 24 };
    [Parameter] public IEnumerable<string> AvailableThemes { get; set; } = new[] { "vs-dark", "vs-light", "hc-black", "hc-light" };

    // ── Action Menu ──
    [Parameter] public List<MenuGroup> ActionMenuGroups { get; set; } = DefaultActionMenuGroups();
    [Parameter] public EventCallback<string> OnActionMenuItem { get; set; }

    // ── Event callbacks ──
    [Parameter] public EventCallback OnBackClick { get; set; }
    [Parameter] public EventCallback OnSaveClick { get; set; }
    [Parameter] public EventCallback OnFormatClick { get; set; }
    [Parameter] public EventCallback OnValidateClick { get; set; }
    [Parameter] public EventCallback OnDownloadClick { get; set; }
    [Parameter] public EventCallback OnCompareClick { get; set; }
    [Parameter] public EventCallback OnPrintClick { get; set; }
    [Parameter] public EventCallback OnUndo { get; set; }
    [Parameter] public EventCallback OnRedo { get; set; }

    // ── Internal state ──
    private bool _showActionMenuDropdown;
    private string _searchValue = "";
    private int _goToLineValue;
    private ElementReference _actionMenuRef;

    private void ToggleActionMenu()
    {
        _showActionMenuDropdown = !_showActionMenuDropdown;
    }

    private void HandleActionMenuFocusOut(FocusEventArgs args)
    {
        // Delay to allow click on menu items to register
        _ = Task.Run(async () =>
        {
            await Task.Delay(200);
            await InvokeAsync(() => _showActionMenuDropdown = false);
        });
    }

    private async Task HandleActionMenuItem(string itemId)
    {
        _showActionMenuDropdown = false;
        await OnActionMenuItem.InvokeAsync(itemId);
    }

    private async Task HandleSearchKeydown(KeyboardEventArgs args)
    {
        if (args.Key == "Enter" && !string.IsNullOrEmpty(_searchValue))
        {
            await OnSearch.InvokeAsync(_searchValue);
        }
    }

    [Parameter] public EventCallback<string> OnSearch { get; set; }

    private async Task HandleGoToLineKeydown(KeyboardEventArgs args)
    {
        if (args.Key == "Enter" && _goToLineValue > 0)
        {
            await OnGoToLine.InvokeAsync(_goToLineValue);
            _goToLineValue = 0;
        }
    }

    [Parameter] public EventCallback<int> OnGoToLine { get; set; }

    private string GetBadgeClass()
    {
        if (!string.IsNullOrEmpty(LanguageBadgeClass)) return LanguageBadgeClass;
        var ext = Path.GetExtension(FileName)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "file-type-json",
            "xml" => "file-type-xml",
            "wsdl" => "file-type-wsdl",
            _ => "file-type-generic"
        };
    }

    private static List<MenuGroup> DefaultActionMenuGroups()
    {
        return new List<MenuGroup>
        {
            new()
            {
                Title = "File Operations",
                Items = new List<MenuItem>
                {
                    new() { Id = "new", Label = "New", Icon = "bi bi-file-earmark", Shortcut = "Ctrl+N" },
                    new() { Id = "open", Label = "Open", Icon = "bi bi-folder-open", Shortcut = "Ctrl+O" },
                    new() { Id = "recent", Label = "Recent Files", Icon = "bi bi-clock-history" },
                    new() { Id = "sep1", Label = "", IsSeparator = true },
                    new() { Id = "save", Label = "Save", Icon = "bi bi-check-lg", Shortcut = "Ctrl+S" },
                    new() { Id = "save-as", Label = "Save As", Icon = "bi bi-file-earmark-plus" },
                    new() { Id = "export", Label = "Export", Icon = "bi bi-box-arrow-up" },
                    new() { Id = "print", Label = "Print", Icon = "bi bi-printer", Shortcut = "Ctrl+P" },
                    new() { Id = "sep2", Label = "", IsSeparator = true },
                    new() { Id = "close", Label = "Close", Icon = "bi bi-x", Shortcut = "Ctrl+W" }
                }
            },
            new()
            {
                Title = "Edit Operations",
                Items = new List<MenuItem>
                {
                    new() { Id = "undo", Label = "Undo", Icon = "bi bi-arrow-counterclockwise", Shortcut = "Ctrl+Z" },
                    new() { Id = "redo", Label = "Redo", Icon = "bi bi-arrow-clockwise", Shortcut = "Ctrl+Y" },
                    new() { Id = "sep3", Label = "", IsSeparator = true },
                    new() { Id = "cut", Label = "Cut", Icon = "bi bi-scissors", Shortcut = "Ctrl+X" },
                    new() { Id = "copy", Label = "Copy", Icon = "bi bi-copy", Shortcut = "Ctrl+C" },
                    new() { Id = "paste", Label = "Paste", Icon = "bi bi-clipboard", Shortcut = "Ctrl+V" },
                    new() { Id = "select-all", Label = "Select All", Icon = "bi bi-ui-radios", Shortcut = "Ctrl+A" },
                    new() { Id = "sep4", Label = "", IsSeparator = true },
                    new() { Id = "duplicate", Label = "Duplicate Line", Icon = "bi bi-files", Shortcut = "Shift+Alt+Down" },
                    new() { Id = "delete-line", Label = "Delete Line", Icon = "bi bi-trash", Shortcut = "Ctrl+Shift+K" },
                    new() { Id = "move-line-up", Label = "Move Line Up", Icon = "bi bi-arrow-up-short", Shortcut = "Alt+Up" },
                    new() { Id = "move-line-down", Label = "Move Line Down", Icon = "bi bi-arrow-down-short", Shortcut = "Alt+Down" }
                }
            },
            new()
            {
                Title = "Find & Replace",
                Items = new List<MenuItem>
                {
                    new() { Id = "find", Label = "Find", Icon = "bi bi-search", Shortcut = "Ctrl+F" },
                    new() { Id = "find-next", Label = "Find Next", Icon = "bi bi-arrow-down", Shortcut = "F3" },
                    new() { Id = "find-prev", Label = "Find Previous", Icon = "bi bi-arrow-up", Shortcut = "Shift+F3" },
                    new() { Id = "replace", Label = "Replace", Icon = "bi bi-arrow-repeat", Shortcut = "Ctrl+H" },
                    new() { Id = "replace-all", Label = "Replace All", Icon = "bi bi-arrow-repeat-all" },
                    new() { Id = "sep5", Label = "", IsSeparator = true },
                    new() { Id = "go-to-line", Label = "Go to Line", Icon = "bi bi-sign-turn-right", Shortcut = "Ctrl+G" },
                    new() { Id = "go-to-symbol", Label = "Go to Symbol", Icon = "bi bi-signpost-2", Shortcut = "Ctrl+Shift+O" }
                }
            },
            new()
            {
                Title = "View & Appearance",
                Items = new List<MenuItem>
                {
                    new() { Id = "toggle-minimap", Label = "Toggle Minimap", Icon = "bi bi-map" },
                    new() { Id = "toggle-breadcrumbs", Label = "Toggle Breadcrumbs", Icon = "bi bi-signpost" },
                    new() { Id = "toggle-word-wrap", Label = "Toggle Word Wrap", Icon = "bi bi-text-wrap", Shortcut = "Alt+Z" },
                    new() { Id = "sep6", Label = "", IsSeparator = true },
                    new() { Id = "theme-dark", Label = "Dark Theme", Icon = "bi bi-moon" },
                    new() { Id = "theme-light", Label = "Light Theme", Icon = "bi bi-sun" },
                    new() { Id = "theme-high-contrast", Label = "High Contrast", Icon = "bi bi-eye" }
                }
            },
            new()
            {
                Title = "XML Tools",
                Items = new List<MenuItem>
                {
                    new() { Id = "xml-validate", Label = "Validate XML", Icon = "bi bi-check-circle" },
                    new() { Id = "xml-format", Label = "Format XML", Icon = "bi bi-file-indent" },
                    new() { Id = "xml-minify", Label = "Minify XML", Icon = "bi bi-compress" },
                    new() { Id = "xml-collapse", Label = "Collapse All", Icon = "bi bi-arrows-collapse" },
                    new() { Id = "xml-expand", Label = "Expand All", Icon = "bi bi-arrows-expand" },
                    new() { Id = "sep7", Label = "", IsSeparator = true },
                    new() { Id = "xml-to-json", Label = "Convert to JSON", Icon = "bi bi-arrow-left-right" },
                    new() { Id = "json-to-xml", Label = "Convert from JSON", Icon = "bi bi-arrow-left-right" },
                    new() { Id = "xml-generate-xsd", Label = "Generate XSD", Icon = "bi bi-file-earmark-code" }
                }
            },
            new()
            {
                Title = "Encoding & Line Endings",
                Items = new List<MenuItem>
                {
                    new() { Id = "encoding-utf8", Label = "UTF-8", Icon = "bi bi-check-lg" },
                    new() { Id = "encoding-utf8-bom", Label = "UTF-8 BOM" },
                    new() { Id = "encoding-utf16", Label = "UTF-16" },
                    new() { Id = "encoding-ascii", Label = "ASCII" },
                    new() { Id = "sep8", Label = "", IsSeparator = true },
                    new() { Id = "line-lf", Label = "Unix (LF)", Icon = "bi bi-check-lg" },
                    new() { Id = "line-crlf", Label = "Windows (CRLF)" },
                    new() { Id = "line-cr", Label = "Mac (CR)" }
                }
            },
            new()
            {
                Title = "Tools & Utilities",
                Items = new List<MenuItem>
                {
                    new() { Id = "compare", Label = "Compare File", Icon = "bi bi-file-diff" },
                    new() { Id = "statistics", Label = "File Statistics", Icon = "bi bi-bar-chart" },
                    new() { Id = "validate", Label = "Validation", Icon = "bi bi-shield-check" }
                }
            },
            new()
            {
                Title = "Help & Settings",
                Items = new List<MenuItem>
                {
                    new() { Id = "shortcuts", Label = "Keyboard Shortcuts", Icon = "bi bi-keyboard", Shortcut = "Ctrl+K Ctrl+S" },
                    new() { Id = "settings", Label = "Settings", Icon = "bi bi-gear" },
                    new() { Id = "reset", Label = "Reset Editor", Icon = "bi bi-arrow-counterclockwise" },
                    new() { Id = "sep9", Label = "", IsSeparator = true },
                    new() { Id = "about", Label = "About", Icon = "bi bi-info-circle" }
                }
            }
        };
    }
}