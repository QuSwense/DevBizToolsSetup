namespace MockCustomerSoapService.Middleware;

using System.Net.Http.Headers;
using System.Text;

public class BasicAuthMiddleware(RequestDelegate next, ILogger<BasicAuthMiddleware> logger)
{
    private const string ExpectedUser = "admin_user";
    private const string ExpectedPassword = "SuperSecretPassword123!";

    public async Task InvokeAsync(HttpContext context)
    {
        // Allow browsing WSDL without credentials for discovery/registration
        if (context.Request.Query.ContainsKey("wsdl") || context.Request.Query.ContainsKey("singleWsdl"))
        {
            await next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("Authorization", out var authHeader))
        {
            logger.LogWarning("Missing Authorization header on SOAP request.");
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            context.Response.Headers.WWWAuthenticate = "Basic realm=\"SOAP Service\"";
            await context.Response.WriteAsync("Unauthorized: Missing Authorization Header");
            return;
        }

        try
        {
            var authHeaderValue = AuthenticationHeaderValue.Parse(authHeader!);
            if ("Basic".Equals(authHeaderValue.Scheme, StringComparison.OrdinalIgnoreCase))
            {
                var credentials = Encoding.UTF8.GetString(Convert.FromBase64String(authHeaderValue.Parameter ?? ""))
                    .Split(':', 2);

                if (credentials.Length == 2 && credentials[0] == ExpectedUser && credentials[1] == ExpectedPassword)
                {
                    await next(context);
                    return;
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error parsing Basic Authentication header.");
        }

        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        await context.Response.WriteAsync("Unauthorized: Invalid Credentials");
    }
}