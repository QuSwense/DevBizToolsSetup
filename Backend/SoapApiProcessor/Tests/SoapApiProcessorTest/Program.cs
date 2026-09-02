namespace SoapApiProcessorTest;

using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Extensions;
using SoapApiProcessorTest.TestScenarios.SoapApplicationServiceTests;
using SoapApiProcessorTest.TestScenarios.SoapExecutionTests;
using SoapApiProcessorTest.TestScenarios.SoapRequestFileTests;
using SoapApiProcessorTest.TestScenarios.SoapWsdlSyncTests;

public class Program
{
    // Map friendly names to service types
    private static readonly Dictionary<string, Type> TestGroups = new(StringComparer.OrdinalIgnoreCase)
    {
        ["AppRegistration"] = typeof(AppRegistrationTestGroup),
        ["AppAuthentication"] = typeof(AppAuthenticationTestGroup),
        ["ManualOperation"] = typeof(ManualOperationTestGroup),
        ["WsdlSync"] = typeof(WsdlSyncTestGroup),
        ["WsdlDiscrepancy"] = typeof(WsdlDiscrepancyTestGroup),
        ["FileUpload"] = typeof(FileUploadTestGroup),
        ["BackwardDiff"] = typeof(BackwardDiffTestGroup),
        ["OutboundClient"] = typeof(OutboundSoapClientTestGroup),
        ["GroupExecution"] = typeof(GroupExecutionTestGroup),
        ["InspectWsdl"] = typeof(InspectWsdlTestGroup),
        ["FullApplication"] = typeof(FullApplicationTestGroup),
        ["Query"] = typeof(QueryTestGroup)
    };

    private static IServiceProvider? _serviceProvider;

    public static async Task Main(string[] args)
    {
        Console.Title = "ServiceHub SOAP Engine Test Suite Driver";

        var host = Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((hostingContext, config) =>
            {
                config.SetBasePath(AppContext.BaseDirectory);
                config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
                config.AddEnvironmentVariables();
            })
            .ConfigureServices((context, services) =>
            {
                string connectionString = context.Configuration.GetConnectionString("ServiceHubDb")
                    ?? throw new InvalidOperationException("ConnectionStrings:ServiceHubDb is missing in appsettings.json.");
                string encryptionKey = context.Configuration["SoapEngine:EncryptionKey"]
                    ?? throw new InvalidOperationException("SoapEngine:EncryptionKey is missing in appsettings.json.");

                services.AddServiceHubSoapEngine(connectionString, encryptionKey);

                // Register all test groups
                foreach (var type in TestGroups.Values.Distinct())
                    services.AddScoped(type);
            })
            .ConfigureLogging(logging =>
            {
                logging.ClearProviders();
                logging.AddConsole();
                logging.SetMinimumLevel(LogLevel.Warning);
            })
            .Build();

        using var scope = host.Services.CreateScope();
        _serviceProvider = scope.ServiceProvider;

        // Command-line mode: dotnet run -- GroupName MethodName
        if (args.Length == 2)
        {
            await RunSingleMethodAsync(args[0], args[1]);
            return;
        }

        // Interactive menu
        while (true)
        {
            Console.Clear();
            Console.WriteLine("==================================================");
            Console.WriteLine("    SERVICEHUB SOAP ENGINE INTEGRATION TESTS     ");
            Console.WriteLine("==================================================");
            Console.WriteLine("Select a test group or use special options:");
            int idx = 1;
            foreach (var key in TestGroups.Keys.OrderBy(k => k))
            {
                Console.WriteLine($"{idx,2}. {key}");
                idx++;
            }
            Console.WriteLine(" A. Run ALL test groups sequentially");
            Console.WriteLine(" 0. Exit");
            Console.Write("\nEnter choice (number, A, or 0): ");

            var input = Console.ReadLine()?.Trim();
            if (input == "0") break;
            if (string.Equals(input, "A", StringComparison.OrdinalIgnoreCase))
            {
                await RunAllGroupsAsync();
                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
                continue;
            }

            if (int.TryParse(input, out int selected) && selected >= 1 && selected <= TestGroups.Count)
            {
                var groupKey = TestGroups.Keys.OrderBy(k => k).ElementAt(selected - 1);
                await RunGroupMenuAsync(groupKey);
            }
            else
            {
                Console.WriteLine("Invalid selection. Press any key to try again.");
                Console.ReadKey();
            }
        }
    }

    private static async Task RunGroupMenuAsync(string groupKey)
    {
        var type = TestGroups[groupKey];
        var service = _serviceProvider!.GetRequiredService(type);

        // Discover public async methods with no parameters
        var methods = type.GetMethods(BindingFlags.Instance | BindingFlags.Public)
            .Where(m => m.ReturnType == typeof(Task) && m.GetParameters().Length == 0)
            .ToList();

        // Separate RunAllAsync from individual tests
        var runAllMethod = methods.FirstOrDefault(m => m.Name == "RunAllAsync");
        var testMethods = methods.Where(m => m.Name != "RunAllAsync").ToList();

        while (true)
        {
            Console.Clear();
            Console.WriteLine($"==================================================");
            Console.WriteLine($"    TEST GROUP: {groupKey}                      ");
            Console.WriteLine($"==================================================");
            if (runAllMethod != null)
                Console.WriteLine(" 0. Run ALL tests in this group");
            Console.WriteLine(" 1..N. Run a specific test method");
            Console.WriteLine(" R. Return to main menu");
            Console.WriteLine();

            if (testMethods.Any())
            {
                for (int i = 0; i < testMethods.Count; i++)
                    Console.WriteLine($" {i + 1,2}. {testMethods[i].Name}");
            }
            else
            {
                Console.WriteLine(" (No individual test methods found)");
            }

            Console.Write("\nEnter choice: ");
            var input = Console.ReadLine()?.Trim();

            if (string.Equals(input, "R", StringComparison.OrdinalIgnoreCase))
                break;

            if (input == "0" && runAllMethod != null)
            {
                await ExecuteMethodAsync(service, runAllMethod);
                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
                continue;
            }

            if (int.TryParse(input, out int selected) && selected >= 1 && selected <= testMethods.Count)
            {
                var method = testMethods[selected - 1];
                await ExecuteMethodAsync(service, method);
                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
            }
            else
            {
                Console.WriteLine("Invalid choice. Press any key to try again.");
                Console.ReadKey();
            }
        }
    }

    private static async Task ExecuteMethodAsync(object service, MethodInfo method)
    {
        Console.WriteLine($"\n--- Executing {method.Name} ---");
        try
        {
            var task = (Task)method.Invoke(service, null)!;
            await task;
            Console.WriteLine($"--- {method.Name} completed ---");
        }
        catch (TargetInvocationException ex)
        {
            Console.WriteLine($"ERROR in {method.Name}: {ex.InnerException?.Message ?? ex.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR in {method.Name}: {ex.Message}");
        }
    }

    private static async Task RunSingleMethodAsync(string groupKey, string methodName)
    {
        if (!TestGroups.TryGetValue(groupKey, out var type))
        {
            Console.WriteLine($"Unknown test group: {groupKey}");
            return;
        }

        var service = _serviceProvider!.GetRequiredService(type);
        var method = type.GetMethod(methodName, BindingFlags.Instance | BindingFlags.Public);
        if (method == null)
        {
            Console.WriteLine($"Method '{methodName}' not found in group '{groupKey}'.");
            return;
        }

        await ExecuteMethodAsync(service, method);
    }

    private static async Task RunAllGroupsAsync()
    {
        Console.WriteLine("\n--- Running ALL test groups sequentially ---");
        foreach (var groupKey in TestGroups.Keys.OrderBy(k => k))
        {
            Console.WriteLine($"\n>>> GROUP: {groupKey}");
            var type = TestGroups[groupKey];
            var service = _serviceProvider!.GetRequiredService(type);
            var runAll = type.GetMethod("RunAllAsync");
            if (runAll != null)
                await ExecuteMethodAsync(service, runAll);
        }
        Console.WriteLine("\n--- All groups completed ---");
    }
}