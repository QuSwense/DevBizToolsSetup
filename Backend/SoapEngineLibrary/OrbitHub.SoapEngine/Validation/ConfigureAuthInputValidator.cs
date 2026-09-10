using OrbitHub.SoapEngine.Core.Models.Inputs;

namespace OrbitHub.SoapEngine.Core.Validation;

public class ConfigureAuthInputValidator : IValidator<ConfigureAuthInputModel>
{
    public ValidationResult Validate(ConfigureAuthInputModel input)
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
            if (input.Credentials is BasicAuthCredentialsInputModel basic)
            {
                if (string.IsNullOrWhiteSpace(basic.Username))
                    errors.Add("BasicAuthCredentialsInputModel: Username is required.");
                if (string.IsNullOrWhiteSpace(basic.Password))
                    errors.Add("BasicAuthCredentialsInputModel: Password is required.");
            }
            else if (input.Credentials is ApiKeyAuthCredentialsInputModel apiKey)
            {
                if (string.IsNullOrWhiteSpace(apiKey.HeaderName))
                    errors.Add("ApiKeyAuthCredentialsInputModel: HeaderName is required.");
                if (string.IsNullOrWhiteSpace(apiKey.ApiKey))
                    errors.Add("ApiKeyAuthCredentialsInputModel: ApiKey is required.");
            }
            else if (input.Credentials is OAuth2CredentialsInputModel oauth)
            {
                if (string.IsNullOrWhiteSpace(oauth.TokenEndpoint))
                    errors.Add("OAuth2CredentialsInputModel: TokenEndpoint is required.");
                if (string.IsNullOrWhiteSpace(oauth.ClientId))
                    errors.Add("OAuth2CredentialsInputModel: ClientId is required.");
                if (string.IsNullOrWhiteSpace(oauth.ClientSecret))
                    errors.Add("OAuth2CredentialsInputModel: ClientSecret is required.");
            }
            else if (input.Credentials is NtlmAuthCredentialsInputModel ntlm)
            {
                if (string.IsNullOrWhiteSpace(ntlm.Username))
                    errors.Add("NtlmAuthCredentialsInputModel: Username is required.");
                if (string.IsNullOrWhiteSpace(ntlm.Password))
                    errors.Add("NtlmAuthCredentialsInputModel: Password is required.");
            }
        }

        return errors.Any() ? ValidationResult.Failure(errors) : ValidationResult.Success();
    }
}