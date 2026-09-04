using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using PdfProcessor.Services;

namespace PdfProcessor.DependencyInjection;

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