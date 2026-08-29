using Microsoft.AspNetCore.Components;

namespace OrbitHub.Ui.Components;

/// <summary>
/// Footer bar for the MonacoEditor component showing file stats, cursor position, and status indicators.
/// </summary>
public partial class MonacoEditorFooter
{
    // ── Left stats ──
    [Parameter] public int TotalCharacters { get; set; }
    [Parameter] public int LinesOfCode { get; set; }
    [Parameter] public int BlankLines { get; set; }
    [Parameter] public int CommentLines { get; set; }
    [Parameter] public long FileSizeBytes { get; set; }
    [Parameter] public string FileEncoding { get; set; } = "UTF-8";
    [Parameter] public string LineEndingFormat { get; set; } = "LF";
    [Parameter] public string LastModifiedTimestamp { get; set; } = "";

    // ── Center stats ──
    [Parameter] public int LineNumber { get; set; } = 1;
    [Parameter] public int ColumnNumber { get; set; } = 1;
    [Parameter] public int CharacterPosition { get; set; }
    [Parameter] public int SelectedLines { get; set; }
    [Parameter] public int SelectedCharacters { get; set; }
    [Parameter] public bool IsOverwriteMode { get; set; }
    [Parameter] public bool IsReadOnly { get; set; }
    [Parameter] public string LanguageMode { get; set; } = "xml";

    // ── Right status ──
    [Parameter] public bool HasValidationErrors { get; set; }
    [Parameter] public bool IsAutoSaveEnabled { get; set; }
    [Parameter] public bool IsSaving { get; set; }
    [Parameter] public bool IsConnected { get; set; } = true;
    [Parameter] public bool IsLoading { get; set; }

    // ── Toggle states ──
    [Parameter] public bool WordWrapEnabled { get; set; } = true;
    [Parameter] public bool MinimapEnabled { get; set; }

    // ── Show/hide ──
    [Parameter] public bool ShowLeftStats { get; set; } = true;
    [Parameter] public bool ShowCenterStats { get; set; } = true;
    [Parameter] public bool ShowRightStats { get; set; } = true;
    [Parameter] public bool ShowWordWrapToggle { get; set; } = true;
    [Parameter] public bool ShowMinimapToggle { get; set; } = true;

    // ── Events ──
    [Parameter] public EventCallback<bool> OnWordWrapToggled { get; set; }
    [Parameter] public EventCallback<bool> OnMinimapToggled { get; set; }
}