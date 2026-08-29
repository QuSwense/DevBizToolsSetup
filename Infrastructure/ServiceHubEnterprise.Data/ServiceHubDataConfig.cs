using LinqToDB;
using LinqToDB.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data.CoreManagement;
using ServiceHubEnterprise.Data.RuleManagement;
using ServiceHubEnterprise.Data.TestManagement;
using ServiceHubEnterprise.Data.UserManagement;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// Dependency injection helpers for registering the linq2db (MSSQL) data contexts.
/// </summary>
public static class ServiceHubDataConfig
{
    private const string ConnectionStringName = "DefaultConnection";

    public static string GetConnectionString(IConfiguration configuration)
    {
        return configuration.GetConnectionString(ConnectionStringName)
            ?? throw new InvalidOperationException($"Connection string '{ConnectionStringName}' was not configured.");
    }

    /// <summary>
    /// Registers all ServiceHub linq2db data contexts against the SQL Server connection string.
    /// </summary>
    public static IServiceCollection AddServiceHubData(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = GetConnectionString(configuration);
        return services.AddServiceHubData(connectionString);
    }

    public static IServiceCollection AddServiceHubData(this IServiceCollection services, string connectionString)
    {
        services.AddLinqToDBContext<CoreDbContext>((_, options) => options.UseSqlServer(connectionString));
        services.AddLinqToDBContext<RuleDbContext>((_, options) => options.UseSqlServer(connectionString));
        services.AddLinqToDBContext<TestDbContext>((_, options) => options.UseSqlServer(connectionString));
        services.AddLinqToDBContext<UserDbContext>((_, options) => options.UseSqlServer(connectionString));

        return services;
    }
}
