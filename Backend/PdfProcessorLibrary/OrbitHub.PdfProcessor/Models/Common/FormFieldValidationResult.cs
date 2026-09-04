public record FormFieldValidationResult(
    bool IsValid,
    string FieldName,
    int? PageNumber,
    string? ActualValue = null,
    string? ExpectedValue = null,
    string? FailureReason = null
);