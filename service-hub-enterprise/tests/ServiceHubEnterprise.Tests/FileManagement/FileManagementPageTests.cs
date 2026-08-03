using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NSubstitute;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.FileManagement.Pages;

namespace ServiceHubEnterprise.Tests.FileManagement;

public class FileManagementPageTests : BunitTestBase
{
    public FileManagementPageTests()
    {
        // Register DbContext mocks for EditorComparer (uses SoapDb, RestDb, FmDb).
        // Each DbContext requires DbContextOptions<T> in its constructor.
        var soapOptions = new DbContextOptionsBuilder<SoapDbContext>().Options;
        var restOptions = new DbContextOptionsBuilder<RestDbContext>().Options;
        var fmOptions = new DbContextOptionsBuilder<FileManagementDbContext>().Options;

        Services.AddSingleton(Substitute.For<SoapDbContext>(soapOptions));
        Services.AddSingleton(Substitute.For<RestDbContext>(restOptions));
        Services.AddSingleton(Substitute.For<FileManagementDbContext>(fmOptions));
    }

    [Fact]
    public void FileLibraryRenders()
    {
        var cut = Render<FileLibrary>();

        cut.Markup.Should().Contain("File Name");
        cut.Markup.Should().Contain("payment_create_001.json");
        cut.Markup.Should().Contain("Search files");
    }

    [Fact]
    public void FileBrowserRenders()
    {
        var cut = Render<FileBrowser>();

        cut.Markup.Should().Contain("File Browser");
        cut.Markup.Should().Contain("WebDAV");
        cut.Markup.Should().Contain("Configure Connection");
    }

    [Fact]
    public void FileViewerRenders()
    {
        var cut = Render<FileViewer>();

        cut.Markup.Should().Contain("No file selected");
        cut.Markup.Should().Contain("Browse File Library");
    }

    [Fact]
    public void EditorComparerRendersEmpty()
    {
        var cut = Render<EditorComparer>();

        // When no query params are provided, it shows the empty state
        cut.Markup.Should().Contain("Editor Comparer");
        cut.Markup.Should().Contain("Browse File Library");
    }
}
