using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class CreateExecutionGroupInputValidator : IValidator<CreateExecutionGroupInput>
{
    public ValidationResult Validate(CreateExecutionGroupInput input)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(input.GroupName))
            errors.Add("GroupName is required.");
        if (string.IsNullOrWhiteSpace(input.CreatedBy))
            errors.Add("CreatedBy is required.");
        if (input.Items == null || input.Items.Count == 0)
            errors.Add("At least one execution group item must be provided.");
        else
        {
            foreach (var item in input.Items)
            {
                if (item.RequestFileId <= 0)
                    errors.Add("Each ExecutionGroupItem must have a valid RequestFileId.");
            }
        }

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}