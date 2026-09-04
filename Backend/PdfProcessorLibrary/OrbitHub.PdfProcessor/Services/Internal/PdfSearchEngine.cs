using Microsoft.Extensions.Logging;
using PdfProcessor.Models.Common;
using System.Text.RegularExpressions;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;

namespace PdfProcessor.Services.Internal;

public class PdfSearchEngine(ILogger<PdfSearchEngine> logger)
{
    public IReadOnlyList<PdfSearchResult> Search(PdfDocument document, IEnumerable<string> searchTerms, bool caseSensitive)
    {
        var results = new List<PdfSearchResult>();
        var terms = searchTerms.Distinct().ToList();
        if (terms.Count == 0) return results;

        logger.LogDebug("Executing wildcard search for {Count} terms across {Pages} pages.", terms.Count, document.NumberOfPages);

        foreach (var page in document.GetPages())
        {
            var words = page.GetWords().ToList();
            foreach (var term in terms)
            {
                var regexPattern = "^" + Regex.Escape(term).Replace("\\*", ".*") + "$";
                var options = caseSensitive ? RegexOptions.None : RegexOptions.IgnoreCase;
                var regex = new Regex(regexPattern, options);

                foreach (var word in words)
                {
                    if (regex.IsMatch(word.Text))
                    {
                        var bounds = new BoundingBox(word.BoundingBox.Left, word.BoundingBox.Top, word.BoundingBox.Width, word.BoundingBox.Height, word.BoundingBox.Bottom, word.BoundingBox.Right);
                        results.Add(new PdfSearchResult(word.Text, page.Number, bounds, GetSurroundingText(words, word)));
                    }
                }
            }
        }
        return results;
    }

    private static string GetSurroundingText(List<Word> words, Word targetWord, int window = 3)
    {
        int index = words.IndexOf(targetWord);
        int start = Math.Max(0, index - window);
        int count = Math.Min(words.Count - start, (window * 2) + 1);
        return string.Join(" ", words.Skip(start).Take(count).Select(w => w.Text));
    }
}