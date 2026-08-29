namespace DocIntercept.Formatting;

/// <summary>
/// A single, independently testable text transformation in the scaffold
/// formatting pipeline. Implementations must operate on <c>\n</c>-normalized
/// content (the orchestrator normalizes line endings and trailing newlines).
/// </summary>
public interface ITextTransformation
{
    /// <summary>Applies this transformation to the source text.</summary>
    string Apply(string content);
}
