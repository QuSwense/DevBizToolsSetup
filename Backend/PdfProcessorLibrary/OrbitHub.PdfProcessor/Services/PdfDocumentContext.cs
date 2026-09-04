using PdfProcessor.Exceptions;
using PdfProcessor.Models.Common;
using PdfProcessor.Models.Fields;
using PdfProcessor.Services.Internal;
using UglyToad.PdfPig;

namespace PdfProcessor.Services;

public sealed class PdfDocumentContext : IDisposable, IAsyncDisposable
{
    private readonly PdfDocument _pdfDocument;
    private readonly Lazy<IReadOnlyList<PdfFormField>> _formFields;
    private readonly Lazy<IReadOnlyList<PageTextContent>> _pages;
    private readonly SpatialTextExtractor _spatialExtractor;
    private readonly PdfSearchEngine _searchEngine;
    private bool _disposed;

    private PdfDocumentContext(
        Stream pdfStream,
        AcroFormExtractor acroExtractor,
        SpatialTextExtractor spatialExtractor,
        PdfSearchEngine searchEngine)
    {
        ArgumentNullException.ThrowIfNull(pdfStream);
        if (!pdfStream.CanRead)
            throw new PdfProcessingException("Provided PDF stream is unreadable or closed.", "StreamValidation");

        _pdfDocument = PdfDocument.Open(pdfStream);
        _spatialExtractor = spatialExtractor;
        _searchEngine = searchEngine;

        _formFields = new Lazy<IReadOnlyList<PdfFormField>>(() => acroExtractor.ExtractFields(_pdfDocument));
        _pages = new Lazy<IReadOnlyList<PageTextContent>>(() => spatialExtractor.ExtractAllPageText(_pdfDocument));
    }

    public static PdfDocumentContext Create(
        Stream pdfStream,
        AcroFormExtractor acroExtractor,
        SpatialTextExtractor spatialExtractor,
        PdfSearchEngine searchEngine,
        bool prefetch = true)
    {
        var context = new PdfDocumentContext(pdfStream, acroExtractor, spatialExtractor, searchEngine);
        if (prefetch)
        {
            _ = context.FormFields;
            _ = context.Pages;
        }
        return context;
    }

    public IReadOnlyList<PdfFormField> FormFields => GetValueIfNotDisposed(_formFields);
    public IReadOnlyList<PageTextContent> Pages => GetValueIfNotDisposed(_pages);
    public int TotalPages => EnsureNotDisposed().NumberOfPages;

    public PageTextContent GetPageText(int pageNumber)
    {
        EnsureNotDisposed();
        var page = Pages.FirstOrDefault(p => p.PageNumber == pageNumber);
        if (page == null)
            throw new ArgumentOutOfRangeException(nameof(pageNumber), "Page number is out of bounds.");
        return page;
    }

    public TextWord? GetWordAtCoordinate(int pageNumber, double x, double y)
    {
        EnsureNotDisposed();
        return _spatialExtractor.GetWordAtCoordinate(_pdfDocument, pageNumber, x, y);
    }

    public string ExtractTextInRegion(int pageNumber, BoundingBox region)
    {
        EnsureNotDisposed();
        return _spatialExtractor.ExtractTextInRegion(_pdfDocument, pageNumber, region);
    }

    public IReadOnlyList<PdfSearchResult> SearchText(IEnumerable<string> searchTerms, bool caseSensitive = false)
    {
        EnsureNotDisposed();
        return _searchEngine.Search(_pdfDocument, searchTerms, caseSensitive);
    }

    /// <summary>
    /// Searches for text across all pages (or a specified page).
    /// Returns a TextSearchResult with page number and coordinate bounds if found; otherwise null.
    /// </summary>
    public TextSearchResult? HasText(string searchText, int? pageNumber = null, bool caseSensitive = false)
    {
        EnsureNotDisposed();
        var comparison = caseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        var pagesToSearch = pageNumber.HasValue
            ? Pages.Where(p => p.PageNumber == pageNumber.Value)
            : Pages;

        foreach (var page in pagesToSearch)
        {
            // First check word-level exact match for precise bounding box
            var wordMatch = page.Words.FirstOrDefault(w => w.Text.Contains(searchText, comparison));
            if (wordMatch != null)
            {
                return new TextSearchResult(wordMatch.Text, page.PageNumber, wordMatch.Bounds, wordMatch);
            }

            // Fallback: line-level match if phrase spans multiple words
            var lineMatch = page.Lines.FirstOrDefault(l => l.Text.Contains(searchText, comparison));
            if (lineMatch != null)
            {
                var firstMatchingWord = lineMatch.Words.FirstOrDefault(w => w.Text.Contains(searchText, comparison)) ?? lineMatch.Words.First();
                return new TextSearchResult(lineMatch.Text, page.PageNumber, lineMatch.Bounds, firstMatchingWord);
            }
        }

        return null;
    }

    public bool HasFormField(string fieldName, int? pageNumber = null)
    {
        EnsureNotDisposed();
        return FormFields.Any(f =>
            string.Equals(f.Name, fieldName, StringComparison.OrdinalIgnoreCase) &&
            (!pageNumber.HasValue || f.PageNumber == pageNumber.Value));
    }

    public FormFieldValidationResult ValidateFormFieldValue(string fieldName, string expectedValue, int? pageNumber = null)
    {
        EnsureNotDisposed();
        var field = FormFields.FirstOrDefault(f =>
            string.Equals(f.Name, fieldName, StringComparison.OrdinalIgnoreCase) &&
            (!pageNumber.HasValue || f.PageNumber == pageNumber.Value));

        if (field == null)
            return new FormFieldValidationResult(false, fieldName, pageNumber, FailureReason: $"Field '{fieldName}' not found.");

        string actualValue = field switch
        {
            PdfTextField tf => tf.Value,
            PdfButtonField bf => bf.IsChecked.ToString(),
            PdfChoiceField cf => string.Join(",", cf.SelectedValues),
            _ => string.Empty
        };

        bool isValid = string.Equals(actualValue, expectedValue, StringComparison.OrdinalIgnoreCase);
        return new FormFieldValidationResult(isValid, fieldName, pageNumber, actualValue, expectedValue, isValid ? null : "Value mismatch.");
    }

    private T GetValueIfNotDisposed<T>(Lazy<T> lazy)
    {
        EnsureNotDisposed();
        return lazy.Value;
    }

    private PdfDocument EnsureNotDisposed()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        return _pdfDocument;
    }

    public void Dispose()
    {
        if (_disposed) return;
        _pdfDocument.Dispose();
        _disposed = true;
    }

    public ValueTask DisposeAsync()
    {
        Dispose();
        return ValueTask.CompletedTask;
    }
}