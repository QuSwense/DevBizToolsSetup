using System.Text.Json;

namespace DocIntercept.Settings;

/// <summary>
/// Settings for the <c>--customize</c> doc-comment interceptor
/// (<see cref="DocIntercept.DescriptionInterceptors"/>).
/// </summary>
public sealed class DescriptionInterceptorsOptions
{
    /// <summary>Whether MS_Description → summary doc comments are injected.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Connection string used to read sys.extended_properties. When empty the
    /// interceptor falls back to the <c>LINQ2DB_CONNECTION</c> environment
    /// variable, then to a development default.
    /// </summary>
    public string? ConnectionString { get; set; }
}

/// <summary>
/// Root settings document read from DocIntercept.settings.json (the file is
/// copied next to the built DLL so both the interceptor and the CLI find it).
/// </summary>
public sealed class DocInterceptSettings
{
    /// <summary>Formatting rules for the <c>format</c> CLI command.</summary>
    public ScaffoldFormatOptions ScaffoldFormat { get; set; } = new();

    /// <summary>Behavior of the doc-comment interceptor.</summary>
    public DescriptionInterceptorsOptions DescriptionInterceptors { get; set; } = new();

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    /// <summary>
    /// Loads settings from <paramref name="path"/>. Missing/unreadable files
    /// yield the built-in defaults rather than failing the scaffold.
    /// </summary>
    public static DocInterceptSettings Load(string? path)
    {
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            return new DocInterceptSettings();

        try
        {
            var json = File.ReadAllText(path);
            var settings = JsonSerializer.Deserialize<DocInterceptSettings>(json, JsonOptions);
            return settings ?? new DocInterceptSettings();
        }
        catch (JsonException ex)
        {
            Console.Error.WriteLine($"Warning: could not parse settings file '{path}': {ex.Message}");
            return new DocInterceptSettings();
        }
    }

    /// <summary>
    /// Absolute path to the DocIntercept.settings.json that sits next to this
    /// assembly in the build output, or <c>null</c> if the location is unknown
    /// (e.g. single-file publish).
    /// </summary>
    public static string? DefaultSettingsPath()
    {
        var location = typeof(DocInterceptSettings).Assembly.Location;
        return string.IsNullOrEmpty(location)
            ? null
            : Path.Combine(Path.GetDirectoryName(location)!, "DocIntercept.settings.json");
    }
}
