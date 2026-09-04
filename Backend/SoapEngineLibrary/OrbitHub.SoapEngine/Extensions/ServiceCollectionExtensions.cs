namespace ServiceHub.SoapEngine.Core.Extensions;

using LinqToDB;
using LinqToDB.AspNet;
using LinqToDB.AspNet.Logging;
using LinqToDB.DataProvider.SqlServer;
using Microsoft.Extensions.DependencyInjection;
using ServiceHub.SoapEngine.Core.Data.Generated;
using ServiceHub.SoapEngine.Core.Data.Repositories;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Parsing;
using ServiceHub.SoapEngine.Core.Services;
using ServiceHub.SoapEngine.Core.Validation;

/// <summary>
/// Extension methods for registering LINQ to DB context, repositories, and SOAP engine core services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers LINQ to DB data context, repositories, and concrete services directly into the DI container.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <param name="connectionString">The SQL Server connection string for ServiceHubDb.</param>
    /// <param name="encryptionBase64Key">A 32-byte (256-bit) Base64-encoded key used for AES-GCM credential encryption.</param>
    public static IServiceCollection AddServiceHubSoapEngine(
        this IServiceCollection services,
        string connectionString,
        string encryptionBase64Key)
    {
        ArgumentNullException.ThrowIfNull(services);

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentException("Connection string cannot be null or empty.", nameof(connectionString));
        }

        if (string.IsNullOrWhiteSpace(encryptionBase64Key))
        {
            throw new ArgumentException("Encryption key cannot be null or empty.", nameof(encryptionBase64Key));
        }

        // 1. Register Stateless Utilities & Cryptography (Singletons)
        services.AddSingleton(new SoapEncryptionService(encryptionBase64Key));
        services.AddSingleton<SoapVersionGeneratorService>();
        services.AddSingleton<SoapFileCompressor>();
        services.AddSingleton<SoapFileDeltaPatcher>();

        // 2. Register LINQ to DB Data Context
        var baseOptions = new DataOptions()
            .UseSqlServer(
                connectionString,
                SqlServerVersion.v2012,
                SqlServerProvider.MicrosoftDataSqlClient);

        // 2. Wrap into typed DataOptions<SoapEngineDataContext> expected by the generated constructor
        var typedOptions = new DataOptions<SoapEngineDataContext>(baseOptions);

        // 3. Register options as Singleton
        services.AddSingleton(typedOptions);
        services.AddSingleton<DataOptions>(typedOptions.Options);

        // 4. Register Context as Scoped using typed options
        services.AddScoped<SoapEngineDataContext>(sp =>
            new SoapEngineDataContext(sp.GetRequiredService<DataOptions<SoapEngineDataContext>>()));

        // 3. Register Typed HttpClients for SOAP & WSDL fetching
        services.AddHttpClient<WsdlParser>();
        services.AddHttpClient<SoapClientService>();

        // 4. Register Concrete Repositories (Scoped per Request/Unit of Work)
        services.AddScoped<SoapApplicationRepository>();
        services.AddScoped<SoapQueryService>();
        services.AddScoped<SoapWsdlSyncRepository>();
        services.AddScoped<SoapOperationRepository>();
        services.AddScoped<SoapRequestFileRepository>();
        services.AddScoped<SoapExecutionRepository>();

        // 5. Register Concrete Parsing & Orchestration Services (Scoped)
        services.AddScoped<SoapApplicationService>();
        services.AddScoped<SoapExecutionGroupRunner>();

        services.AddScoped<IValidator<RegisterApplicationInput>, RegisterApplicationInputValidator>();
        services.AddScoped<IValidator<CreateFullApplicationInput>, CreateFullApplicationInputValidator>();
        services.AddScoped<IValidator<UpdateFullApplicationInput>, UpdateFullApplicationInputValidator>();
        services.AddScoped<IValidator<EditApplicationInput>, EditApplicationInputValidator>();
        services.AddScoped<IValidator<SyncWsdlInput>, SyncWsdlInputValidator>();
        services.AddScoped<IValidator<InspectWsdlInput>, InspectWsdlInputValidator>();
        services.AddScoped<IValidator<UploadRequestFileInput>, UploadRequestFileInputValidator>();
        services.AddScoped<IValidator<ConfigureAuthInput>, ConfigureAuthInputValidator>();
        services.AddScoped<IValidator<CreateManualOperationInput>, CreateManualOperationInputValidator>();
        services.AddScoped<IValidator<CreateExecutionGroupInput>, CreateExecutionGroupInputValidator>();
        services.AddScoped<IValidator<ExecuteGroupRunInput>, ExecuteGroupRunInputValidator>();
        services.AddScoped<IValidator<SaveOperationInput>, SaveOperationInputValidator>();

        return services;
    }
}