namespace OrbitHub.Common.Models;

using OrbitHub.Common.Helpers;

/// <summary>
/// Auto-generated or manually created resource accessor with lazy loading
/// </summary>
public class SharedResources : BaseResourceManager
{
    private static readonly Lazy<SharedResources> _instance = new(
        () => new SharedResources(),
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    private SharedResources() : base(nameof(SharedResources))
    {
    }

    public static SharedResources Instance => _instance.Value;

    // Resource properties
    public string WelcomeMessage => GetString(nameof(WelcomeMessage));
    public string SubmitButton => GetString(nameof(SubmitButton));
    public string CancelButton => GetString(nameof(CancelButton));
    public string DashboardTitle => GetString(nameof(DashboardTitle));

    // Formatted strings
    public string GetGreeting(string name) => GetFormattedString("GreetingFormat", new object[] { name });
    public string GetErrorMessage(string errorCode) => GetFormattedString("ErrorMessage", new object[] { errorCode });
}