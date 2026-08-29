namespace OrbitHub.Common.Models;

using OrbitHub.Common.Helpers;

/// <summary>
/// Strongly-typed helper for EnumResources
/// </summary>
public class EnumResources : BaseResourceManager
{
    private static readonly Lazy<EnumResources> _instance = new(
        () => new EnumResources(),
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    private EnumResources() : base(nameof(EnumResources))
    {
    }

    public static EnumResources Instance => _instance.Value;

    // Resource properties
    public string WelcomeMessage => GetString(nameof(WelcomeMessage));
    public string SubmitButton => GetString(nameof(SubmitButton));
    public string CancelButton => GetString(nameof(CancelButton));
    public string DashboardTitle => GetString(nameof(DashboardTitle));

    // Formatted strings
    public string GetGreeting(string name) => GetFormattedString("GreetingFormat", new object[] { name });
    public string GetErrorMessage(string errorCode) => GetFormattedString("ErrorMessage", new object[] { errorCode });
}