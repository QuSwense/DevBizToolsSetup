namespace OrbitHub.SoapEngine.Core.Extensions;

using LinqToDB;
using LinqToDB.DataProvider.SqlServer;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.Data.TestManagement;
using OrbitHub.SoapEngine.Core.Models.Inputs;
using OrbitHub.SoapEngine.Core.Services;

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
        services.AddSingleton<SoapFileCompressor>();
        services.AddSingleton<SoapFileDeltaPatcher>();

        // 2. Register Data Contexts for hybrid paged queries + SP repos
        var baseOptions = new DataOptions()
            .UseSqlServer(
                connectionString,
                SqlServerVersion.v2012,
                SqlServerProvider.MicrosoftDataSqlClient);

        var typedOptions = new DataOptions<ServiceAppDbContext>(baseOptions);
        var testTypedOptions = new DataOptions<TestDbContext>(baseOptions);
        services.AddSingleton(typedOptions);
        services.AddSingleton(testTypedOptions);
        services.AddSingleton<DataOptions>(typedOptions.Options);
        services.AddScoped<ServiceAppDbContext>(sp =>
            new ServiceAppDbContext(sp.GetRequiredService<DataOptions<ServiceAppDbContext>>()));
        services.AddScoped<TestDbContext>(sp =>
            new TestDbContext(sp.GetRequiredService<DataOptions<TestDbContext>>()));

        // 3. Register OrbitHub.Data SP repositories + IUnitOfWork
        services.AddRepositories();

        // 4. Register Typed HttpClients for SOAP & WSDL fetching
        services.AddHttpClient<WsdlParser>();
        services.AddHttpClient<SoapClientService>();

        // 5. Register Wrapper Repositories (Scoped per Request/Unit of Work)
        services.AddScoped<ServiceApplicationRepository>();
        services.AddScoped<ServiceOperationRepository>();
        services.AddScoped<ServiceRequestFileRepository>();
        services.AddScoped<ServiceDefinitionSyncRepository>();
        services.AddScoped<ServiceExecutionAuditRepository>();

        // 6. Register Query Service
        services.AddScoped<SoapQueryService>();

        // 7. Register Orchestration Services (Scoped)
        services.AddScoped<SoapApplicationService>();
        services.AddScoped<SoapExecutionGroupRunner>();

        // 8. Register Validators
        services.AddScoped<IValidator<RegisterApplicationInputModel>, RegisterApplicationInputValidator>();
        services.AddScoped<IValidator<CreateFullApplicationInputModel>, CreateFullApplicationInputValidator>();
        services.AddScoped<IValidator<UpdateFullApplicationInputModel>, UpdateFullApplicationInputValidator>();
        services.AddScoped<IValidator<EditApplicationInputModel>, EditApplicationInputValidator>();
        services.AddScoped<IValidator<SyncWsdlInputModel>, SyncWsdlInputValidator>();
        services.AddScoped<IValidator<InspectWsdlInputModel>, InspectWsdlInputValidator>();
        services.AddScoped<IValidator<UploadRequestFileInputModel>, UploadRequestFileInputValidator>();
        services.AddScoped<IValidator<ConfigureAuthInputModel>, ConfigureAuthInputValidator>();
        services.AddScoped<IValidator<CreateManualOperationInputModel>, CreateManualOperationInputValidator>();
        services.AddScoped<IValidator<CreateExecutionGroupInputModel>, CreateExecutionGroupInputValidator>();
        services.AddScoped<IValidator<ExecuteGroupRunInputModel>, ExecuteGroupRunInputValidator>();
        services.AddScoped<IValidator<SaveOperationInputModel>, SaveOperationInputValidator>();

        return services;
    }
}