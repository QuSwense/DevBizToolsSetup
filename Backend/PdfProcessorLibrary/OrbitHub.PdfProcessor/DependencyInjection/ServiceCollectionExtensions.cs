using Microsoft.Extensions.DependencyInjection;
using OrbitHub.PdfProcessor.Core.Services;

namespace OrbitHub.PdfProcessor.Core.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddPdfProcessor(this IServiceCollection services)
    {
        services.AddSingleton<PdfProcessorService>();

        // Register concrete context factories directly
        services.AddSingleton<PdfContextFactory>();
        services.AddSingleton<PdfEditorContextFactory>();

        return services;
    }
}