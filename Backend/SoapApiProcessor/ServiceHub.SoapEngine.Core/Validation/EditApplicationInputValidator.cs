using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class EditApplicationInputValidator : IValidator<EditApplicationInput>
{
    public ValidationResult Validate(EditApplicationInput input)
    {
        var errors = new List<string>();

        if (input.AppId <= 0)
            errors.Add("AppId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(input.AppName))
            errors.Add("AppName is required.");
        if (string.IsNullOrWhiteSpace(input.BaseUrl))
            errors.Add("BaseUrl is required.");
        if (string.IsNullOrWhiteSpace(input.UpdatedBy))
            errors.Add("UpdatedBy is required.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}