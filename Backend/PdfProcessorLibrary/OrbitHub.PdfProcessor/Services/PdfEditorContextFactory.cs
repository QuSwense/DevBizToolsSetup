using Microsoft.Extensions.Logging;

namespace OrbitHub.PdfProcessor.Core.Services;

public class PdfEditorContextFactory(ILoggerFactory loggerFactory)
{
    public async Task<PdfEditorContext> CreateEditorAsync(Stream pdfStream, CancellationToken cancellationToken = default)
    {
        return await PdfEditorContext.CreateAsync(pdfStream, loggerFactory.CreateLogger<PdfEditorContext>(), cancellationToken);
    }
}