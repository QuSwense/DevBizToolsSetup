namespace OrbitHub.Common.Models;

using OrbitHub.Common.Helpers;

/// <summary>
/// Auto-generated or manually created resource accessor with lazy loading
/// </summary>
public class SharedResourcesModel : BaseResourceManager
{
    private static readonly Lazy<SharedResourcesModel> _instance = new(
        () => new SharedResourcesModel(),
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    private SharedResourcesModel() : base("SharedResources")
    {
    }

    public static SharedResourcesModel Instance => _instance.Value;

    // Resource properties
    public string WelcomeMessage => GetString(nameof(WelcomeMessage));
    public string SubmitButton => GetString(nameof(SubmitButton));
    public string CancelButton => GetString(nameof(CancelButton));
    public string DashboardTitle => GetString(nameof(DashboardTitle));

    // Formatted strings
    public string GetGreeting(string name) => GetFormattedString("GreetingFormat", new object[] { name });
    public string GetErrorMessage(string errorCode) => GetFormattedString("ErrorMessage", new object[] { errorCode });
}