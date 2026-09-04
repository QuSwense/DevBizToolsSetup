namespace ServiceHub.SoapEngine.Core.Validation;

public class ValidationResult
{
    public bool IsValid { get; }
    public IReadOnlyList<string> Errors { get; }

    private ValidationResult(bool isValid, List<string> errors)
    {
        IsValid = isValid;
        Errors = errors.AsReadOnly();
    }

    public static ValidationResult Success() => new(true, new List<string>());
    public static ValidationResult Failure(string error) => new(false, new List<string> { error });
    public static ValidationResult Failure(IEnumerable<string> errors) => new(false, [.. errors]);
}