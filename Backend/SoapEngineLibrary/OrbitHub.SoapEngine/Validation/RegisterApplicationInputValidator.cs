using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class RegisterApplicationInputValidator : IValidator<RegisterApplicationInput>
{
    public ValidationResult Validate(RegisterApplicationInput input)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(input.AppName))
            errors.Add("AppName is required.");
        if (string.IsNullOrWhiteSpace(input.BaseUrl))
            errors.Add("BaseUrl is required.");
        if (string.IsNullOrWhiteSpace(input.CreatedBy))
            errors.Add("CreatedBy is required.");
        // If WsdlRelativeUrl is provided, it must not be empty
        if (input.WsdlRelativeUrl != null && string.IsNullOrWhiteSpace(input.WsdlRelativeUrl))
            errors.Add("WsdlRelativeUrl, if provided, cannot be empty.");
        // If DirectWsdlStream is provided, it must be readable
        if (input.DirectWsdlStream != null && !input.DirectWsdlStream.CanRead)
            errors.Add("DirectWsdlStream must be a readable stream.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}