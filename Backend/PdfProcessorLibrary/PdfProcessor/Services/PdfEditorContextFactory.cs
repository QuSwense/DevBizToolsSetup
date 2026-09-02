using Microsoft.Extensions.Logging;

namespace PdfProcessor.Services;

public class PdfEditorContextFactory(ILoggerFactory loggerFactory)
{
    public async Task<PdfEditorContext> CreateEditorAsync(Stream pdfStream, CancellationToken cancellationToken = default)
    {
        return await PdfEditorContext.CreateAsync(pdfStream, loggerFactory.CreateLogger<PdfEditorContext>(), cancellationToken);
    }
}