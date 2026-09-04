using Microsoft.Extensions.Logging;
using PdfProcessor.Models.Common;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;

namespace PdfProcessor.Services.Internal;

public class SpatialTextExtractor(ILogger<SpatialTextExtractor> logger)
{
    public IReadOnlyList<PageTextContent> ExtractAllPageText(PdfDocument document)
    {
        logger.LogDebug("Extracting text line-by-line and word-by-word across all pages.");
        return [.. document.GetPages().Select(ExtractPageText)];
    }

    public PageTextContent ExtractPageText(Page page)
    {
        var rawWords = page.GetWords().ToList();
        var words = rawWords.Select(w => new TextWord(
            w.Text,
            new BoundingBox(w.BoundingBox.Left, w.BoundingBox.Top, w.BoundingBox.Width, w.BoundingBox.Height, w.BoundingBox.Bottom, w.BoundingBox.Right),
            page.Number
        )).ToList();

        // Group words into lines by Y coordinate baseline proximity (allowing 3-point tolerance)
        var lines = rawWords
            .GroupBy(w => Math.Round(w.BoundingBox.Bottom / 3.0) * 3.0)
            .OrderByDescending(g => g.Key)
            .Select((g, idx) =>
            {
                var sortedWords = g.OrderBy(w => w.BoundingBox.Left).ToList();
                var lineText = string.Join(" ", sortedWords.Select(w => w.Text));
                var left = sortedWords.Min(w => w.BoundingBox.Left);
                var right = sortedWords.Max(w => w.BoundingBox.Right);
                var top = sortedWords.Max(w => w.BoundingBox.Top);
                var bottom = sortedWords.Min(w => w.BoundingBox.Bottom);

                var lineWords = sortedWords.Select(w => new TextWord(
                    w.Text,
                    new BoundingBox(w.BoundingBox.Left, w.BoundingBox.Top, w.BoundingBox.Width, w.BoundingBox.Height, w.BoundingBox.Bottom, w.BoundingBox.Right),
                    page.Number
                )).ToList();

                return new TextLine(
                    idx + 1,
                    lineText,
                    new BoundingBox(left, top, right - left, top - bottom, bottom, right),
                    page.Number,
                    lineWords
                );
            }).ToList();

        return new PageTextContent(page.Number, page.Text, lines, words);
    }

    public TextWord? GetWordAtCoordinate(PdfDocument document, int pageNumber, double x, double y)
    {
        if (pageNumber < 1 || pageNumber > document.NumberOfPages) return null;
        var page = document.GetPage(pageNumber);

        var match = page.GetWords().FirstOrDefault(w =>
            x >= w.BoundingBox.Left && x <= w.BoundingBox.Right &&
            y >= w.BoundingBox.Bottom && y <= w.BoundingBox.Top);

        if (match == null) return null;

        return new TextWord(
            match.Text,
            new BoundingBox(match.BoundingBox.Left, match.BoundingBox.Top, match.BoundingBox.Width, match.BoundingBox.Height, match.BoundingBox.Bottom, match.BoundingBox.Right),
            pageNumber
        );
    }

    public string ExtractTextInRegion(PdfDocument document, int pageNumber, BoundingBox region)
    {
        if (pageNumber < 1 || pageNumber > document.NumberOfPages)
        {
            throw new ArgumentOutOfRangeException(nameof(pageNumber), "Page number is outside PDF bounds.");
        }
        var page = document.GetPage(pageNumber);
        var matchingWords = page.GetWords()
            .Where(w => w.BoundingBox.Left >= region.Left &&
                        w.BoundingBox.Right <= region.Right &&
                        w.BoundingBox.Bottom >= region.Bottom &&
                        w.BoundingBox.Top <= region.Top)
            .Select(w => w.Text);

        return string.Join(" ", matchingWords);
    }
}