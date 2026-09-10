using OrbitHub.SoapEngine.Core.Models.Inputs;

namespace OrbitHub.SoapEngine.Core.Validation;

public class CreateManualOperationInputValidator : IValidator<CreateManualOperationInputModel>
{
    public ValidationResult Validate(CreateManualOperationInputModel input)
    {
        var errors = new List<string>();

        if (input.AppId <= 0)
            errors.Add("AppId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(input.OperationName))
            errors.Add("OperationName is required.");
        if (string.IsNullOrWhiteSpace(input.InputRootElementName))
            errors.Add("InputRootElementName is required.");
        if (string.IsNullOrWhiteSpace(input.OutputRootElementName))
            errors.Add("OutputRootElementName is required.");
        if (string.IsNullOrWhiteSpace(input.TargetNamespace))
            errors.Add("TargetNamespace is required.");
        if (string.IsNullOrWhiteSpace(input.CreatedBy))
            errors.Add("CreatedBy is required.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}