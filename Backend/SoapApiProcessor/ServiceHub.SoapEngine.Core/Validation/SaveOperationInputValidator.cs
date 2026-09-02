using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class SaveOperationInputValidator : IValidator<SaveOperationInput>
{
    public ValidationResult Validate(SaveOperationInput input)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(input.OperationName))
            errors.Add("OperationName is required.");
        // Other fields are optional and will be defaulted in service

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}