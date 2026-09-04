namespace PdfProcessor.Models.Common;

public record PdfSearchResult(
    string MatchedTerm,
    int PageNumber,
    BoundingBox Bounds,
    string SurroundingSnippet
);