using OrbitHub.SoapEngine.Core.Models.Inputs;

namespace OrbitHub.SoapEngine.Core.Validation;

public class ExecuteGroupRunInputValidator : IValidator<ExecuteGroupRunInputModel>
{
    public ValidationResult Validate(ExecuteGroupRunInputModel input)
    {
        var errors = new List<string>();

        if (input.ExecutionGroupId <= 0)
            errors.Add("ExecutionGroupId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(input.ExecutedBy))
            errors.Add("ExecutedBy is required.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}