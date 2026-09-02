namespace PdfProcessor.Models.Common;

public record TextSearchResult(
    string MatchedText,
    int PageNumber,
    BoundingBox Bounds,
    TextWord WordMatch
);