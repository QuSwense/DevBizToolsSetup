namespace PdfProcessor.Exceptions;

/// <summary>
/// Custom application-wide exception wrapper for PDF processing failures.
/// </summary>
public class PdfProcessingException(string message, string? stepContext = null, Exception? innerException = null) : Exception(message, innerException)
{
    public string? StepContext { get; } = stepContext;
}