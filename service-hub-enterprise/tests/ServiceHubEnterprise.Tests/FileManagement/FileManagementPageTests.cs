using ServiceHubEnterprise.FileManagement.Pages;

namespace ServiceHubEnterprise.Tests.FileManagement;

public class FileManagementPageTests : BunitTestBase
{
    [Fact]
    public void FileLibraryRenders()
    {
        var cut = Render<FileLibrary>();

        cut.Markup.Should().Contain("4 files");
        cut.Markup.Should().Contain("File Name");
        cut.Markup.Should().Contain("payment_create_001.json");
    }

    [Fact]
    public void FileBrowserRenders()
    {
        var cut = Render<FileBrowser>();

        cut.Markup.Should().Contain("New Folder");
        cut.Markup.Should().Contain("service-hub-files");
        cut.Markup.Should().Contain("requests/");
    }

    [Fact]
    public void FileViewerRenders()
    {
        var cut = Render<FileViewer>();

        cut.Markup.Should().Contain("No file selected");
        cut.Markup.Should().Contain("Browse File");
        cut.Markup.Should().Contain("Open File");
    }

    [Fact]
    public void EditorComparerRenders()
    {
        var cut = Render<EditorComparer>();

        cut.Markup.Should().Contain("Editor Comparer");
        cut.Markup.Should().Contain("Select Files to Compare");
    }
}
