namespace ServiceHubEnterprise.Common.Helpers;

using System.Globalization;
using System.Threading;

/// <summary>
/// Manages application language/culture settings
/// </summary>
public static class LanguageManager
{
    private static CultureInfo _currentCulture = CultureInfo.CurrentUICulture;
    private static readonly Lock _lock = new();
    private static event Action<CultureInfo>? _languageChanged;

    /// <summary>
    /// Event raised when language changes
    /// </summary>
    public static event Action<CultureInfo>? LanguageChanged
    {
        add
        {
            lock (_lock)
            {
                _languageChanged += value;
                value?.Invoke(_currentCulture);
            }
        }
        remove
        {
            lock (_lock)
            {
                _languageChanged -= value;
            }
        }
    }

    /// <summary>
    /// Gets the current culture
    /// </summary>
    public static CultureInfo CurrentCulture
    {
        get
        {
            lock (_lock)
            {
                return _currentCulture;
            }
        }
    }

    /// <summary>
    /// Changes the application language
    /// </summary>
    /// <param name="cultureName">Culture name (e.g., en-US, de-DE)</param>
    public static void SetLanguage(string cultureName)
    {
        ArgumentException.ThrowIfNullOrEmpty(cultureName);

        try
        {
            var culture = new CultureInfo(cultureName);

            lock (_lock)
            {
                if (_currentCulture.Name == culture.Name)
                {
                    return;
                }

                Thread.CurrentThread.CurrentCulture = culture;
                Thread.CurrentThread.CurrentUICulture = culture;
                CultureInfo.DefaultThreadCurrentCulture = culture;
                CultureInfo.DefaultThreadCurrentUICulture = culture;

                _currentCulture = culture;

                JsonResourceLoader.ClearCache();

                var handlers = _languageChanged;
                handlers?.Invoke(culture);
            }
        }
        catch (CultureNotFoundException)
        {
            var invariant = CultureInfo.InvariantCulture;
            lock (_lock)
            {
                Thread.CurrentThread.CurrentUICulture = invariant;
                _currentCulture = invariant;
            }
        }
    }
}