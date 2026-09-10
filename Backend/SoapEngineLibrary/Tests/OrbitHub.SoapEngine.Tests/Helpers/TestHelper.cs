namespace OrbitHub.SoapEngine.Tests.Helpers;

/// <summary>
/// Shared utility methods for test groups.
/// </summary>
public static class TestHelper
{
    /// <summary>
    /// Executes a test action safely, catching and logging any unhandled exception
    /// with a formatted test name and full stack trace.
    /// </summary>
    public static async Task ExecuteSafelyAsync(string testName, Func<Task> testAction)
    {
        try
        {
            await testAction();
        }
        catch (Exception ex)
        {
            Console.WriteLine($" [ERROR] '{testName}' threw unhandled exception: {ex.GetType().Name} - {ex.Message}");
            Console.WriteLine($" [STACK TRACE] {ex}");
        }
    }
}
