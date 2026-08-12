namespace ServiceHubEnterprise.Common.Helpers;

using System.Collections.Concurrent;
using System.Globalization;
using System.Text.Json;
using System.Threading;

/// <summary>
/// Thread-safe JSON resource loader that loads resources once per culture
/// </summary>
public static class JsonResourceLoader
{
    private static readonly ConcurrentDictionary<string, Lazy<ConcurrentDictionary<string, string>>> _allResources = [];
    private static readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        AllowTrailingCommas = true,
        ReadCommentHandling = JsonCommentHandling.Skip
    };
    private static readonly string _resourcesPath;
    private static readonly Lock _directoryLock = new();

    static JsonResourceLoader()
    {
        var baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
        _resourcesPath = Path.Combine(baseDirectory, "Resources");

        if (!Directory.Exists(_resourcesPath))
        {
            lock (_directoryLock)
            {
                if (!Directory.Exists(_resourcesPath))
                {
                    Directory.CreateDirectory(_resourcesPath);
                }
            }
        }
    }

    /// <summary>
    /// Loads resources for a specific resource file - Thread-safe with Lazy
    /// </summary>
    /// <param name="resourceName">Name of the resource (without extension)</param>
    /// <param name="culture">Culture to load (uses CurrentUICulture if null)</param>
    /// <returns>Dictionary of key-value pairs for the specified culture</returns>
    public static ConcurrentDictionary<string, string> LoadResources(string resourceName, CultureInfo? culture = null)
    {
        ArgumentException.ThrowIfNullOrEmpty(resourceName);

        culture ??= CultureInfo.CurrentUICulture;
        var cultureName = culture.Name;
        var cacheKey = $"{resourceName}_{cultureName}";

        var lazyResources = _allResources.GetOrAdd(cacheKey,
            key => new Lazy<ConcurrentDictionary<string, string>>(
                () => LoadResourceFile(resourceName, cultureName),
                LazyThreadSafetyMode.ExecutionAndPublication
            ));

        return lazyResources.Value;
    }

    /// <summary>
    /// Loads a single resource file for a specific culture
    /// </summary>
    private static ConcurrentDictionary<string, string> LoadResourceFile(string resourceName, string cultureName)
    {
        var resources = new ConcurrentDictionary<string, string>();

        try
        {
            // Try culture-specific file first
            var cultureFilePath = Path.Combine(_resourcesPath, $"{resourceName}.{cultureName}.json");
            if (File.Exists(cultureFilePath))
            {
                LoadJsonFile(cultureFilePath, resources);
                return resources;
            }

            // Try default file
            var defaultFilePath = Path.Combine(_resourcesPath, $"{resourceName}.json");
            if (File.Exists(defaultFilePath))
            {
                LoadJsonFile(defaultFilePath, resources);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading resource {resourceName} for culture {cultureName}: {ex.Message}");
        }

        return resources;
    }

    /// <summary>
    /// Loads a JSON file into the target dictionary
    /// </summary>
    private static void LoadJsonFile(string filePath, ConcurrentDictionary<string, string> targetDictionary)
    {
        try
        {
            var json = File.ReadAllText(filePath);
            var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json, _jsonOptions);

            if (dict is not null)
            {
                foreach (var kvp in dict)
                {
                    targetDictionary.TryAdd(kvp.Key, kvp.Value);
                }
            }
        }
        catch (JsonException ex)
        {
            Console.WriteLine($"Invalid JSON in {filePath}: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Gets a specific resource value by key for a given resource and culture
    /// </summary>
    public static string GetString(string resourceName, string key, CultureInfo? culture = null)
    {
        ArgumentException.ThrowIfNullOrEmpty(resourceName);
        ArgumentException.ThrowIfNullOrEmpty(key);

        var resources = LoadResources(resourceName, culture);
        return resources.TryGetValue(key, out var value) ? value : string.Empty;
    }

    /// <summary>
    /// Thread-safe clear all resources
    /// </summary>
    public static void ClearCache()
    {
        _allResources.Clear();
    }

    /// <summary>
    /// Thread-safe clear resources for specific resource and culture
    /// </summary>
    public static void ClearCache(string resourceName, CultureInfo? culture = null)
    {
        if (string.IsNullOrEmpty(resourceName))
        {
            return;
        }

        culture ??= CultureInfo.CurrentUICulture;
        var cacheKey = $"{resourceName}_{culture.Name}";
        _allResources.TryRemove(cacheKey, out _);
    }
}