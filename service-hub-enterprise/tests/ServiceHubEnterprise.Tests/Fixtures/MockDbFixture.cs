using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace ServiceHubEnterprise.Tests.Fixtures;

/// <summary>
/// Locates the repo-root <c>mock_db/</c> folder from the test output directory and provides
/// helpers to build IConfiguration and isolated temp mock databases for store/repo tests.
/// </summary>
public static class MockDbFixture
{
    /// <summary>Absolute path to the repository root (where ServiceHubEnterprise.slnx lives).</summary>
    public static string RepoRoot { get; } = FindRepoRoot();

    /// <summary>Absolute path to the real repo mock_db folder.</summary>
    public static string MockDbPath => Path.Combine(RepoRoot, "mock_db");

    private static string FindRepoRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "ServiceHubEnterprise.slnx")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }

        throw new DirectoryNotFoundException(
            $"Could not locate ServiceHubEnterprise.slnx walking up from {AppContext.BaseDirectory}.");
    }

    /// <summary>
    /// Creates an isolated temp mock_db directory pre-seeded with the given files
    /// (name -> raw content). MockDbLoader always requires a wsdl-content-map.json to exist,
    /// so one is written (as "{}") unless explicitly overridden.
    /// </summary>
    public static TempMockDb CreateTempMockDb(params (string Name, string Content)[] files)
        => new(files);
}

/// <summary>
/// A disposable temp mock database directory. Writes JSON via <see cref="WriteJson{T}"/>
/// using the same case-insensitive options as the app's MockDbLoader.
/// </summary>
public sealed class TempMockDb : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public string Path { get; }

    public TempMockDb(params (string Name, string Content)[] files)
    {
        Path = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "she-tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(Path);

        // MockDbLoader's ctor loads wsdl-content-map.json synchronously and throws if the
        // directory is missing, so always provide an (empty) map unless the caller supplies one.
        if (!files.Any(f => f.Name == "wsdl-content-map.json"))
        {
            WriteFile("wsdl-content-map.json", "{}");
        }

        foreach (var (name, content) in files)
        {
            WriteFile(name, content);
        }
    }

    public void WriteFile(string name, string content)
        => File.WriteAllText(System.IO.Path.Combine(Path, name), content);

    public void WriteJson<T>(string name, T value, JsonSerializerOptions? options = null)
    {
        var json = JsonSerializer.Serialize(value, options ?? JsonOptions);
        WriteFile(name, json);
    }

    public IConfiguration BuildConfiguration(string? currentUser = "Priya Sharma", int? requestFilesDelayMs = null)
    {
        var values = new Dictionary<string, string?>
        {
            ["MockDb:Path"] = Path,
            ["Users:CurrentUser"] = currentUser
        };

        if (requestFilesDelayMs is not null)
        {
            values["MockDb:RequestFilesDelayMs"] = requestFilesDelayMs.Value.ToString();
        }

        return new ConfigurationBuilder()
            .AddInMemoryCollection(values)
            .Build();
    }

    public void Dispose()
    {
        try
        {
            if (Directory.Exists(Path))
            {
                Directory.Delete(Path, recursive: true);
            }
        }
        catch
        {
            // Best-effort cleanup only.
        }
    }
}
