using Microsoft.Extensions.Logging;
using PdfProcessor.Services.Internal;

namespace PdfProcessor.Services;

public class PdfContextFactory(ILoggerFactory loggerFactory)
{
    private readonly AcroFormExtractor _acroExtractor = new(loggerFactory.CreateLogger<AcroFormExtractor>());
    private readonly SpatialTextExtractor _spatialExtractor = new(loggerFactory.CreateLogger<SpatialTextExtractor>());
    private readonly PdfSearchEngine _searchEngine = new(loggerFactory.CreateLogger<PdfSearchEngine>());

    public async Task<PdfDocumentContext> CreateContextAsync(Stream pdfStream, bool prefetch = true, CancellationToken cancellationToken = default)
    {
        return await Task.Run(() =>
            PdfDocumentContext.Create(pdfStream, _acroExtractor, _spatialExtractor, _searchEngine, prefetch), cancellationToken);
    }
}