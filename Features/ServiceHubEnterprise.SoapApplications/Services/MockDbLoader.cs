using Microsoft.Extensions.Configuration;
using System.Text.Json;

namespace ServiceHubEnterprise.SoapApplications.Services;

/// <summary>
/// Loads mock/seed data from JSON files and WSDL content files
/// stored under the solution-root mock_db/ folder.
/// Registered as a singleton so the content is read once at startup.
/// </summary>
public class MockDbLoader
{
    private readonly string _mockDbPath;
    private readonly Dictionary<string, string> _wsdlContentMap;
    private readonly Dictionary<string, string> _wsdlContentCache = [];
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private static readonly JsonSerializerOptions WriteJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DictionaryKeyPolicy = JsonNamingPolicy.CamelCase
    };

    public MockDbLoader(IConfiguration configuration)
    {
        // Resolve mock_db path from configuration, with fallback
        _mockDbPath = ResolveMockDbPath(configuration);
        _wsdlContentMap = LoadJsonAsync<Dictionary<string, string>>("Wsdl/wsdl-content-map.json")
            .GetAwaiter().GetResult();
    }

    private static string ResolveMockDbPath(IConfiguration configuration)
    {
        var configPath = configuration.GetValue<string>("MockDb:Path");

        if (string.IsNullOrEmpty(configPath))
        {
            throw new InvalidOperationException(
                "Configuration key 'MockDb:Path' is not set. " +
                "Add a 'MockDb' section with a 'Path' value in appsettings.json pointing to the mock_db directory.");
        }

        var resolved = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), configPath));

        if (!Directory.Exists(resolved))
        {
            throw new DirectoryNotFoundException(
                $"The mock database directory configured at 'MockDb:Path' ('{configPath}') was not found. " +
                $"Resolved full path: '{resolved}'. Ensure the directory exists or correct the path in appsettings.json.");
        }

        return resolved;
    }

    /// <summary>
    /// Loads and deserializes a JSON file from the mock_db folder.
    /// </summary>
    public async Task<T> LoadJsonAsync<T>(string fileName)
    {
        var path = Path.Combine(_mockDbPath, fileName);
        if (!File.Exists(path))
            return default!;

        var json = await File.ReadAllTextAsync(path).ConfigureAwait(false);
        return JsonSerializer.Deserialize<T>(json, JsonOptions) ?? default!;
    }

    /// <summary>
    /// Serializes a value and writes it back to a JSON file in the mock_db folder.
    /// Uses camelCase naming (matching the seed files) with indented formatting.
    /// </summary>
    public async Task SaveJsonAsync<T>(string fileName, T value)
    {
        var path = Path.Combine(_mockDbPath, fileName);
        var json = JsonSerializer.Serialize(value, WriteJsonOptions);
        await File.WriteAllTextAsync(path, json).ConfigureAwait(false);
    }

    /// <summary>
    /// Loads a WSDL content file by its logical key (e.g. "basic", "customer", "orders").
    /// Uses the Wsdl/wsdl-content-map.json to resolve key -> file name.
    /// Results are cached in memory after first load.
    /// </summary>
    public async Task<string> LoadWsdlContentAsync(string key)
    {
        if (_wsdlContentCache.TryGetValue(key, out var cached))
            return cached;

        if (!_wsdlContentMap.TryGetValue(key, out var fileName))
            return "";

        var path = Path.Combine(_mockDbPath, fileName);
        if (!File.Exists(path))
            return "";

        var content = await File.ReadAllTextAsync(path).ConfigureAwait(false);
        _wsdlContentCache[key] = content;
        return content;
    }

    /// <summary>
    /// Loads a WSDL file by its file name (e.g. "wsdl_basic.wsdl") from the Wsdl/ folder.
    /// Returns an empty string when the file does not exist.
    /// </summary>
    public async Task<string> LoadWsdlFileAsync(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName))
            return "";

        var path = Path.Combine(_mockDbPath, "Wsdl", fileName);
        if (!File.Exists(path))
            return "";

        return await File.ReadAllTextAsync(path).ConfigureAwait(false);
    }

    /// <summary>
    /// Persists WSDL content to a file in the Wsdl/ folder (e.g. "wsdl_basic.wsdl").
    /// </summary>
    public async Task SaveWsdlFileAsync(string fileName, string content)
    {
        if (string.IsNullOrWhiteSpace(fileName))
            throw new ArgumentException("A WSDL file name is required.", nameof(fileName));

        var path = Path.Combine(_mockDbPath, "Wsdl", fileName);
        await File.WriteAllTextAsync(path, content).ConfigureAwait(false);
    }

    /// <summary>
    /// Returns the file names of all .wsdl files available in the Wsdl/ folder.
    /// </summary>
    public string[] GetWsdlFileNames()
    {
        var dir = Path.Combine(_mockDbPath, "Wsdl");
        if (!Directory.Exists(dir))
            return [];

        return Directory.GetFiles(dir, "*.wsdl")
            .Select(path => Path.GetFileName(path) ?? "")
            .OrderBy(f => f, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    /// <summary>
    /// Preloads and caches all WSDL content files at once.
    /// Call during startup to avoid first-use latency.
    /// </summary>
    public async Task PreloadAllWsdlContentAsync()
    {
        foreach (var (key, fileName) in _wsdlContentMap)
        {
            var path = Path.Combine(_mockDbPath, fileName);
            if (File.Exists(path))
            {
                var content = await File.ReadAllTextAsync(path).ConfigureAwait(false);
                _wsdlContentCache[key] = content;
            }
        }
    }
}
