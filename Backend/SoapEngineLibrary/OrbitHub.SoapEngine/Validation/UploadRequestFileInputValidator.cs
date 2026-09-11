using OrbitHub.SoapEngine.Core.Models.Inputs;

namespace OrbitHub.SoapEngine.Core.Validation;

public class UploadRequestFileInputValidator : IValidator<UploadRequestFileInputModel>
{
    public ValidationResult Validate(UploadRequestFileInputModel input)
    {
        var errors = new List<string>();

        if (input.OperationId <= 0)
            errors.Add("OperationId must be a positive integer.");
        if (string.IsNullOrWhiteSpace(input.FileName))
            errors.Add("FileName is required.");
        if (input.FileStream == null || !input.FileStream.CanRead)
            errors.Add("FileStream must be a readable stream.");
        if (string.IsNullOrWhiteSpace(input.CreatedBy))
            errors.Add("CreatedBy is required.");

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}