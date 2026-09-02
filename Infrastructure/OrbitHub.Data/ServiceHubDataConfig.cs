using LinqToDB;
using LinqToDB.DataProvider.SqlServer;
using LinqToDB.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.CoreManagement;
using OrbitHub.Data.FileVersionManagement;
using OrbitHub.Data.IndexingManagement;
using OrbitHub.Data.PermissionsManagement;
using OrbitHub.Data.Repositories;
using OrbitHub.Data.RuleManagement;
using OrbitHub.Data.SoapManagement;
using OrbitHub.Data.TestManagement;
using OrbitHub.Data.UIManagement;
using OrbitHub.Data.UserManagement;
using OrbitHub.Data.WsdlManagement;
using OrbitHub.Data.RestManagement;

namespace OrbitHub.Data;

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
        services.AddLinqToDBContext<CoreDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<FileManagementDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<IndexingDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<PermissionsDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<RuleDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<SoapDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<TestDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<UiDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<UserDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<WsdlDbContext>((_, options) => UseSqlServer(options, connectionString));
        services.AddLinqToDBContext<RestDbContext>((_, options) => UseSqlServer(options, connectionString));

        services.AddRepositories();

        return services;
    }

    private static DataOptions UseSqlServer(DataOptions options, string connectionString)
    {
        return options.UseSqlServer(connectionString, SqlServerVersion.AutoDetect, SqlServerProvider.MicrosoftDataSqlClient);
    }
}
