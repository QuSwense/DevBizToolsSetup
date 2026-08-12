using FluentAssertions;
using ServiceHubEnterprise.Ui.Components;
using ServiceHubEnterprise.Ui.Models;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class MonacoEditorTests : BunitTestBase
{
    [Fact]
    public void RendersToolbarAndFooterByDefault()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.FileName, "test.xml")
            .Add(x => x.Content, "<root></root>"));

        cut.FindAll(".monaco-editor-toolbar").Should().HaveCount(1);
        cut.FindAll(".monaco-editor-footer").Should().HaveCount(1);
        cut.Markup.Should().Contain("test.xml");
        cut.Markup.Should().Contain("monaco-editor-host");
    }

    [Fact]
    public void HidesToolbarWhenShowToolbarFalse()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.ShowToolbar, false)
            .Add(x => x.Content, "<root></root>"));

        cut.FindAll(".monaco-editor-toolbar").Should().BeEmpty();
        cut.FindAll(".monaco-editor-footer").Should().HaveCount(1);
    }

    [Fact]
    public void HidesFooterWhenShowFooterFalse()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.ShowFooter, false)
            .Add(x => x.Content, "<root></root>"));

        cut.FindAll(".monaco-editor-footer").Should().BeEmpty();
        cut.FindAll(".monaco-editor-toolbar").Should().HaveCount(1);
    }

    [Fact]
    public void RendersCustomToolbarContent()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.ShowToolbar, true)
            .Add(x => x.ToolbarContent, b => b.AddContent(0, "<span class=\"custom-toolbar\">Custom</span>"))
            .Add(x => x.Content, "<root></root>"));

        cut.Markup.Should().Contain("custom-toolbar");
        cut.Markup.Should().Contain("Custom");
    }

    [Fact]
    public void RendersCustomFooterContent()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.ShowFooter, true)
            .Add(x => x.FooterContent, b => b.AddContent(0, "<span class=\"custom-footer\">Custom Footer</span>"))
            .Add(x => x.Content, "<root></root>"));

        cut.Markup.Should().Contain("custom-footer");
        cut.Markup.Should().Contain("Custom Footer");
    }

    [Fact]
    public void RendersLoadingState()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.IsLoading, true));

        cut.Markup.Should().Contain("Loading editor");
    }

    [Fact]
    public void RendersErrorState()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.HasError, true)
            .Add(x => x.ErrorMessage, "Boom"));

        cut.Markup.Should().Contain("Boom");
        cut.Markup.Should().Contain("Retry");
    }

    [Fact]
    public void ShowsLanguageBadgeFromFileName()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.FileName, "data.json")
            .Add(x => x.Content, "{}"));

        cut.Markup.Should().Contain("json");
    }

    [Fact]
    public void TracksUnsavedChangesIndicator()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.FileName, "test.xml")
            .Add(x => x.Content, "<root></root>")
            .Add(x => x.HasUnsavedChanges, true));

        cut.Markup.Should().Contain("Unsaved");
    }

    [Fact]
    public void DisablesCompareButtonWhenNoPreviousVersion()
    {
        var cut = Render<MonacoEditor>(p => p
            .Add(x => x.FileName, "test.xml")
            .Add(x => x.Content, "<root></root>")
            .Add(x => x.ShowCompareButton, false));

        // Compare button not rendered when ShowCompareButton=false
        cut.FindAll("button[title='Compare with saved version']").Should().BeEmpty();
    }
}

public class MonacoEditorToolbarTests : BunitTestBase
{
    [Fact]
    public void RendersDefaultButtons()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.FileName, "test.xml"));

        cut.FindAll("button").Count.Should().BeGreaterThan(3);
        cut.Markup.Should().Contain("test.xml");
    }

    [Fact]
    public void HidesSaveButtonWhenShowSaveButtonFalse()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.ShowSaveButton, false));

        cut.FindAll("button[title='Save (Ctrl+S)']").Should().BeEmpty();
    }

    [Fact]
    public void HidesFontSelectorWhenShowFontSelectorFalse()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.ShowFontSelector, false));

        cut.FindAll(".toolbar-select").Should().BeEmpty();
    }

    [Fact]
    public void HidesSearchBoxWhenShowSearchBoxFalse()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.ShowSearchBox, false));

        cut.Markup.Should().NotContain("toolbar-search-input");
    }

    [Fact]
    public void ActionMenuShowsAllGroups()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.ShowActionMenu, true));

        cut.Markup.Should().Contain("File Operations");
        cut.Markup.Should().Contain("Edit Operations");
        cut.Markup.Should().Contain("Find &amp; Replace");
        cut.Markup.Should().Contain("View &amp; Appearance");
        cut.Markup.Should().Contain("XML Tools");
        cut.Markup.Should().Contain("Encoding &amp; Line Endings");
        cut.Markup.Should().Contain("Tools &amp; Utilities");
        cut.Markup.Should().Contain("Help &amp; Settings");
    }

    [Fact]
    public void HidesActionMenuWhenShowActionMenuFalse()
    {
        var cut = Render<MonacoEditorToolbar>(p => p
            .Add(x => x.ShowActionMenu, false));

        cut.Markup.Should().NotContain("File Operations");
    }
}

public class MonacoEditorFooterTests : BunitTestBase
{
    [Fact]
    public void ShowsStatsByDefault()
    {
        var cut = Render<MonacoEditorFooter>(p => p
            .Add(x => x.TotalCharacters, 100)
            .Add(x => x.LinesOfCode, 10)
            .Add(x => x.FileEncoding, "UTF-8"));

        cut.Markup.Should().Contain("100 chars");
        cut.Markup.Should().Contain("10 LOC");
        cut.Markup.Should().Contain("UTF-8");
    }

    [Fact]
    public void HidesLeftStatsWhenShowLeftStatsFalse()
    {
        var cut = Render<MonacoEditorFooter>(p => p
            .Add(x => x.ShowLeftStats, false)
            .Add(x => x.TotalCharacters, 100));

        cut.Markup.Should().NotContain("100 chars");
    }

    [Fact]
    public void ShowsValidationErrorIcon()
    {
        var cut = Render<MonacoEditorFooter>(p => p
            .Add(x => x.HasValidationErrors, true));

        cut.Markup.Should().Contain("bi-exclamation-circle");
    }

    [Fact]
    public void ShowsReadOnlyIndicator()
    {
        var cut = Render<MonacoEditorFooter>(p => p
            .Add(x => x.IsReadOnly, true));

        cut.Markup.Should().Contain("RO");
    }

    [Fact]
    public void ShowsFileSizeFormatted()
    {
        var cut = Render<MonacoEditorFooter>(p => p
            .Add(x => x.FileSizeBytes, 2048));

        cut.Markup.Should().Contain("2.0 KB");
    }
}

public class MonacoComparerToolbarTests : BunitTestBase
{
    [Fact]
    public void ShowsDiffCounter()
    {
        var cut = Render<MonacoComparerToolbar>(p => p
            .Add(x => x.TotalDifferences, 5)
            .Add(x => x.CurrentDifference, 2));

        cut.Markup.Should().Contain("2 / 5");
    }

    [Fact]
    public void HidesNavigationWhenShowNavigationFalse()
    {
        var cut = Render<MonacoComparerToolbar>(p => p
            .Add(x => x.ShowNavigation, false));

        cut.FindAll("button[title='Previous difference']").Should().BeEmpty();
        cut.FindAll("button[title='Next difference']").Should().BeEmpty();
    }

    [Fact]
    public void ShowsViewModeToggles()
    {
        var cut = Render<MonacoComparerToolbar>(p => p
            .Add(x => x.ShowViewModeToggle, true));

        cut.Markup.Should().Contain("Side by side view");
        cut.Markup.Should().Contain("Inline view");
    }

    [Fact]
    public void HidesSwapWhenShowSwapButtonFalse()
    {
        var cut = Render<MonacoComparerToolbar>(p => p
            .Add(x => x.ShowSwapButton, false));

        cut.FindAll("button[title='Swap versions']").Should().BeEmpty();
    }
}

public class MonacoComparerFooterTests : BunitTestBase
{
    [Fact]
    public void ShowsDiffStats()
    {
        var cut = Render<MonacoComparerFooter>(p => p
            .Add(x => x.TotalDifferences, 10)
            .Add(x => x.Additions, 4)
            .Add(x => x.Deletions, 6));

        cut.Markup.Should().Contain("10 diff");
        cut.Markup.Should().Contain("+4");
        cut.Markup.Should().Contain("-6");
    }

    [Fact]
    public void ShowsNoDifferencesMessage()
    {
        var cut = Render<MonacoComparerFooter>(p => p
            .Add(x => x.TotalDifferences, 0));

        cut.Markup.Should().Contain("No differences found");
    }

    [Fact]
    public void ShowsProcessingState()
    {
        var cut = Render<MonacoComparerFooter>(p => p
            .Add(x => x.IsProcessing, true));

        cut.Markup.Should().Contain("Processing");
    }

    [Fact]
    public void ShowsErrorState()
    {
        var cut = Render<MonacoComparerFooter>(p => p
            .Add(x => x.HasError, true)
            .Add(x => x.ErrorMessage, "Load failed"));

        cut.Markup.Should().Contain("Error");
    }
}

public class MonacoDiffEditorTests : BunitTestBase
{
    [Fact]
    public void RendersWithLabels()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.OriginalLabel, "v1.xml")
            .Add(x => x.ModifiedLabel, "v2.xml")
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.Markup.Should().Contain("v1.xml");
        cut.Markup.Should().Contain("v2.xml");
        cut.Markup.Should().Contain("monaco-diff-host");
    }

    [Fact]
    public void HidesHeaderWhenShowHeaderFalse()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.ShowHeader, false)
            .Add(x => x.OriginalLabel, "v1.xml")
            .Add(x => x.ModifiedLabel, "v2.xml")
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.Markup.Should().NotContain("ORIGINAL");
        cut.Markup.Should().NotContain("MODIFIED");
    }

    [Fact]
    public void HidesControlsWhenShowControlsFalse()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.ShowControls, false)
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.FindAll(".monaco-diff-controls").Should().BeEmpty();
    }

    [Fact]
    public void HidesFooterWhenShowFooterFalse()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.ShowFooter, false)
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.FindAll(".monaco-diff-footer").Should().BeEmpty();
    }

    [Fact]
    public void RendersCustomControlsContent()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.ControlsContent, b => b.AddContent(0, "<span class=\"custom-controls\">Ctrl</span>"))
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.Markup.Should().Contain("custom-controls");
    }

    [Fact]
    public void RendersCustomFooterContent()
    {
        var cut = Render<MonacoDiffEditor>(p => p
            .Add(x => x.FooterContent, b => b.AddContent(0, "<span class=\"custom-diff-footer\">Stats</span>"))
            .Add(x => x.OriginalContent, "<a/>")
            .Add(x => x.ModifiedContent, "<b/>"));

        cut.Markup.Should().Contain("custom-diff-footer");
    }
}

public class DiffViewModeTests
{
    [Fact]
    public void EnumValuesAreCorrect()
    {
        ((int)EDiffViewMode.SideBySide).Should().Be(0);
        ((int)EDiffViewMode.Inline).Should().Be(1);
    }
}