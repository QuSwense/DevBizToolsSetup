using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class CreateFullApplicationInputValidator : IValidator<CreateFullApplicationInput>
{
    public ValidationResult Validate(CreateFullApplicationInput input)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(input.AppName))
            errors.Add("AppName is required.");
        if (string.IsNullOrWhiteSpace(input.BaseUrl))
            errors.Add("BaseUrl is required.");
        if (string.IsNullOrWhiteSpace(input.CreatedBy))
            errors.Add("CreatedBy is required.");
        if (input.Operations == null || input.Operations.Count == 0)
            errors.Add("At least one operation must be provided.");
        else
        {
            foreach (var op in input.Operations)
            {
                if (string.IsNullOrWhiteSpace(op.OperationName))
                    errors.Add("Each operation must have an OperationName.");
                // If InputRootElementName or OutputRootElementName missing, they will be defaulted in service, so not mandatory
            }
        }
        // If AuthType is provided, AuthCredentials must also be provided
        if (input.AuthType.HasValue && input.AuthCredentials == null)
            errors.Add("AuthCredentials must be provided when AuthType is specified.");
        // If AuthCredentials provided, AuthType must be provided
        if (input.AuthCredentials != null && !input.AuthType.HasValue)
            errors.Add("AuthType must be provided when AuthCredentials are specified.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}