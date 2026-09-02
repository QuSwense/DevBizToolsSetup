using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class SyncWsdlInputValidator : IValidator<SyncWsdlInput>
{
    public ValidationResult Validate(SyncWsdlInput input)
    {
        var errors = new List<string>();

        if (input.AppId <= 0)
            errors.Add("AppId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(input.SyncedBy))
            errors.Add("SyncedBy is required.");

        // Must provide either WsdlUrl or WsdlFileStream, but not both (optional)
        bool hasUrl = !string.IsNullOrWhiteSpace(input.WsdlUrl);
        bool hasStream = input.WsdlFileStream != null;

        if (!hasUrl && !hasStream)
            errors.Add("Either WsdlUrl or WsdlFileStream must be provided.");
        if (hasUrl && hasStream)
            errors.Add("Provide either WsdlUrl or WsdlFileStream, not both.");
        if (hasStream && !input.WsdlFileStream!.CanRead)
            errors.Add("WsdlFileStream must be a readable stream.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}