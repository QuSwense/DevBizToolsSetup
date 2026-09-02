using ServiceHub.SoapEngine.Core.Models.Inputs;

namespace ServiceHub.SoapEngine.Core.Validation;

public class ConfigureAuthInputValidator : IValidator<ConfigureAuthInput>
{
    public ValidationResult Validate(ConfigureAuthInput input)
    {
        var errors = new List<string>();

        if (input.AppId <= 0)
            errors.Add("AppId must be a positive integer.");
        if (input.Credentials == null)
            errors.Add("Credentials must be provided.");
        if (string.IsNullOrWhiteSpace(input.ConfiguredBy))
            errors.Add("ConfiguredBy is required.");

        // Additional checks for specific credential types
        if (input.Credentials != null)
        {
            if (input.Credentials is BasicAuthCredentials basic)
            {
                if (string.IsNullOrWhiteSpace(basic.Username))
                    errors.Add("BasicAuthCredentials: Username is required.");
                if (string.IsNullOrWhiteSpace(basic.Password))
                    errors.Add("BasicAuthCredentials: Password is required.");
            }
            else if (input.Credentials is ApiKeyAuthCredentials apiKey)
            {
                if (string.IsNullOrWhiteSpace(apiKey.HeaderName))
                    errors.Add("ApiKeyAuthCredentials: HeaderName is required.");
                if (string.IsNullOrWhiteSpace(apiKey.ApiKey))
                    errors.Add("ApiKeyAuthCredentials: ApiKey is required.");
            }
            else if (input.Credentials is OAuth2Credentials oauth)
            {
                if (string.IsNullOrWhiteSpace(oauth.TokenEndpoint))
                    errors.Add("OAuth2Credentials: TokenEndpoint is required.");
                if (string.IsNullOrWhiteSpace(oauth.ClientId))
                    errors.Add("OAuth2Credentials: ClientId is required.");
                if (string.IsNullOrWhiteSpace(oauth.ClientSecret))
                    errors.Add("OAuth2Credentials: ClientSecret is required.");
            }
            else if (input.Credentials is NtlmAuthCredentials ntlm)
            {
                if (string.IsNullOrWhiteSpace(ntlm.Username))
                    errors.Add("NtlmAuthCredentials: Username is required.");
                if (string.IsNullOrWhiteSpace(ntlm.Password))
                    errors.Add("NtlmAuthCredentials: Password is required.");
            }
        }

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}