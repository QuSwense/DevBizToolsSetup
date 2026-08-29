namespace OrbitHub.Common.Helpers;

using System.Globalization;
using System.Threading;

/// <summary>
/// Thread-safe base class for strongly-typed resource access
/// </summary>
public abstract class BaseResourceManager
{
    private readonly string _resourceName;
    private readonly ReaderWriterLockSlim _cacheLock = new();

    /// <summary>
    /// Initializes a new instance of the BaseResourceManager class
    /// </summary>
    /// <param name="resourceName">Name of the resource file</param>
    protected BaseResourceManager(string resourceName)
    {
        ArgumentException.ThrowIfNullOrEmpty(resourceName);
        _resourceName = resourceName;
        LanguageManager.LanguageChanged += OnLanguageChanged;
    }

    /// <summary>
    /// Gets a resource value by key
    /// </summary>
    /// <param name="key">Resource key</param>
    /// <param name="culture">Optional culture override</param>
    /// <returns>Localized string value</returns>
    protected string GetString(string key, CultureInfo? culture = null)
    {
        ArgumentException.ThrowIfNullOrEmpty(key);
        return JsonResourceLoader.GetString(_resourceName, key, culture);
    }

    /// <summary>
    /// Gets a formatted resource value
    /// </summary>
    /// <param name="key">Resource key</param>
    /// <param name="args">Format arguments</param>
    /// <param name="culture">Optional culture override</param>
    /// <returns>Formatted localized string</returns>
    protected string GetFormattedString(string key, object[] args, CultureInfo? culture = null)
    {
        var value = GetString(key, culture);
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }

        try
        {
            return string.Format(culture ?? LanguageManager.CurrentCulture, value, args);
        }
        catch
        {
            return value;
        }
    }

    /// <summary>
    /// Handles language changes - clears cache for this resource
    /// </summary>
    private void OnLanguageChanged(CultureInfo newCulture)
    {
        _cacheLock.EnterWriteLock();
        try
        {
            JsonResourceLoader.ClearCache(_resourceName, newCulture);
        }
        finally
        {
            _cacheLock.ExitWriteLock();
        }
    }
}