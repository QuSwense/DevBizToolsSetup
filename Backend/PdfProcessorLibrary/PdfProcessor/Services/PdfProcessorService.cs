using Microsoft.Extensions.Logging;
using PdfProcessor.Models.Common;
using PdfProcessor.Models.Fields;

namespace PdfProcessor.Services;

public class PdfProcessorService(PdfContextFactory contextFactory)
{
    public async Task<PdfDocumentContent> ExtractContentAsync(Stream pdfStream, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: true, cancellationToken);
        return new PdfDocumentContent(context.FormFields, context.Pages);
    }

    public async Task<PageTextContent> ExtractPageTextAsync(Stream pdfStream, int pageNumber, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: false, cancellationToken);
        return context.GetPageText(pageNumber);
    }

    public async Task<IReadOnlyList<PdfFormField>> ExtractFieldsAsync(Stream pdfStream, int? pageNumber = null, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: true, cancellationToken);
        return pageNumber.HasValue
            ? [.. context.FormFields.Where(f => f.PageNumber == pageNumber.Value)]
            : context.FormFields;
    }

    public async Task<TextWord?> GetWordAtCoordinateAsync(Stream pdfStream, int pageNumber, double x, double y, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: false, cancellationToken);
        return context.GetWordAtCoordinate(pageNumber, x, y);
    }

    public async Task<string> ExtractTextInRegionAsync(Stream pdfStream, int pageNumber, BoundingBox searchRegion, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: false, cancellationToken);
        return context.ExtractTextInRegion(pageNumber, searchRegion);
    }

    public async Task<IReadOnlyList<PdfSearchResult>> SearchTextAsync(Stream pdfStream, IEnumerable<string> searchTerms, bool caseSensitive = false, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: false, cancellationToken);
        return context.SearchText(searchTerms, caseSensitive);
    }

    public async Task<IReadOnlyList<string>> GetFieldNamesAsync(Stream pdfStream, int? pageNumber = null, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: true, cancellationToken);
        return [.. context.FormFields
            .Where(f => !pageNumber.HasValue || f.PageNumber == pageNumber.Value)
            .Select(f => f.Name)
            .Where(n => !string.IsNullOrEmpty(n))];
    }

    public async Task<bool> HasFormFieldAsync(Stream pdfStream, string fieldName, int? pageNumber = null, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: true, cancellationToken);
        return context.HasFormField(fieldName, pageNumber);
    }

    public async Task<FormFieldValidationResult> ValidateFormFieldValueAsync(Stream pdfStream, string fieldName, string expectedValue, int? pageNumber = null, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: true, cancellationToken);
        return context.ValidateFormFieldValue(fieldName, expectedValue, pageNumber);
    }

    public async Task<bool> HasTextAsync(Stream pdfStream, string searchText, int? pageNumber = null, bool caseSensitive = false, CancellationToken cancellationToken = default)
    {
        await using var context = await contextFactory.CreateContextAsync(pdfStream, prefetch: false, cancellationToken);

        // Check if the result is not null to return a boolean
        return context.HasText(searchText, pageNumber, caseSensitive) != null;
    }
}