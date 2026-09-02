using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class UpdateFullApplicationInputValidator : IValidator<UpdateFullApplicationInput>
{
    public ValidationResult Validate(UpdateFullApplicationInput input)
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
        if (input.UpdateAuthentication)
        {
            if (!input.AuthType.HasValue)
                errors.Add("AuthType must be provided when UpdateAuthentication is true.");
            if (input.AuthCredentials == null)
                errors.Add("AuthCredentials must be provided when UpdateAuthentication is true.");
        }
        if (input.Operations == null || input.Operations.Count == 0)
            errors.Add("At least one operation must be provided.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}