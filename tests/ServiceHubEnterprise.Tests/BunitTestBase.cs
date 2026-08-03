using Bunit;
using Bunit.TestDoubles;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.Tests;

/// <summary>
/// Base class for all bUnit component tests.
/// xUnit creates a fresh instance per test, so every test gets an isolated
/// <see cref="BunitContext"/> (component under test + services + JS interop).
/// </summary>
public abstract class BunitTestBase : BunitContext
{
    protected BunitTestBase()
    {
        // Components across the solution call a variety of JS interop (grid context-menu
        // bridge, Monaco, collapse.js ...). Loose mode swallows unplanned calls while still
        // recording them in JSInterop.Invocations, so tests can assert on them when needed.
        JSInterop.Mode = JSRuntimeMode.Loose;
    }

    /// <summary>
    /// Registers a BunitNavigationManager (bUnit 2.x's FakeNavigationManager) for
    /// components that inject NavigationManager, and returns it for assertions.
    /// </summary>
    protected BunitNavigationManager AddFakeNavigationManager()
    {
        var nav = new BunitNavigationManager(this);
        Services.AddSingleton<NavigationManager>(nav);
        return nav;
    }

    /// <summary>
    /// Builds an IConfiguration for tests. <paramref name="mockDbPath"/> may be an absolute
    /// path (recommended) or a relative path — stores resolve it with
    /// Path.GetFullPath(Path.Combine(CWD, path)), and Combine yields the rooted path when an
    /// absolute path is supplied.
    /// </summary>
    protected static IConfiguration BuildConfiguration(
        string mockDbPath,
        string? currentUser = "Priya Sharma",
        int? requestFilesDelayMs = null)
    {
        var values = new Dictionary<string, string?>
        {
            ["MockDb:Path"] = mockDbPath,
            ["Users:CurrentUser"] = currentUser
        };

        if (requestFilesDelayMs is not null)
        {
            values["MockDb:RequestFilesDelayMs"] = requestFilesDelayMs.Value.ToString();
        }

        return new ConfigurationBuilder()
            .AddInMemoryCollection(values)
            .Build();
    }
}
