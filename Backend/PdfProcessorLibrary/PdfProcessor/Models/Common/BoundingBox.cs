namespace PdfProcessor.Models.Common;

/// <summary>
/// Immutable spatial bounding box coordinates for PDF elements.
/// </summary>
public readonly record struct BoundingBox(
    double Left,
    double Top,
    double Width,
    double Height,
    double Bottom,
    double Right
);