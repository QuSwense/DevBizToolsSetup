using OrbitHub.SoapEngine.Core.Models.Inputs;

namespace OrbitHub.SoapEngine.Core.Validation;

public class InspectWsdlInputValidator : IValidator<InspectWsdlInputModel>
{
    public ValidationResult Validate(InspectWsdlInputModel input)
    {
        var errors = new List<string>();

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