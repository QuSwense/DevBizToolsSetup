using Microsoft.Extensions.Configuration;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// Helper for resolving the ServiceHub SQLite database connection string.
/// Reads from <c>ConnectionStrings:ServiceHub</c> configuration key.
/// Default: <c>Data Source=servicehub.db</c> in the current working directory.
/// </summary>
public static class ServiceHubDataConfig
{
    public const string ConnectionStringName = "ServiceHub";

    /// <summary>
    /// Gets the SQLite connection string from configuration, or the default.
    /// </summary>
    public static string GetConnectionString(IConfiguration configuration)
    {
        var cs = configuration.GetConnectionString(ConnectionStringName);
        return !string.IsNullOrWhiteSpace(cs)
            ? cs
            : "Data Source=servicehub.db";
    }
}