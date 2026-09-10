namespace OrbitHub.SoapEngine.Core.Validation;

public class SaveOperationInputValidator : IValidator<SaveOperationInputModel>
{
    public ValidationResult Validate(SaveOperationInputModel input)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(input.OperationName))
            errors.Add("OperationName is required.");
        // Other fields are optional and will be defaulted in service

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}