namespace MockOAuthSoapService.Middleware;

using System.Collections.Concurrent;

public static class OAuthTokenStore
{
    // Valid Client Credentials
    public const string ExpectedClientId = "client_app_id_99";
    public const string ExpectedClientSecret = "secret_key_888";

    // Active Issued Access Tokens
    public static ConcurrentDictionary<string, DateTime> ActiveTokens { get; } = new();
}

public class OAuthAuthMiddleware(RequestDelegate next, ILogger<OAuthAuthMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        // 1. Bypass WSDL discovery queries
        if (context.Request.Query.ContainsKey("wsdl") || context.Request.Query.ContainsKey("singleWsdl"))
        {
            await next(context);
            return;
        }

        // 2. Handle OAuth2 Token Endpoint (/connect/token)
        if (context.Request.Path.Equals("/connect/token", StringComparison.OrdinalIgnoreCase) &&
            HttpMethods.IsPost(context.Request.Method))
        {
            await HandleTokenRequestAsync(context);
            return;
        }

        // 3. Validate Bearer Token for SOAP requests
        if (!context.Request.Headers.TryGetValue("Authorization", out var authHeader))
        {
            logger.LogWarning("Missing Authorization header on OAuth SOAP request.");
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Unauthorized: Missing Bearer Authorization Header");
            return;
        }

        string headerValue = authHeader.ToString();
        if (headerValue.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            string token = headerValue["Bearer ".Length..].Trim();
            if (OAuthTokenStore.ActiveTokens.TryGetValue(token, out var expiry) && expiry > DateTime.UtcNow)
            {
                await next(context);
                return;
            }
        }

        logger.LogWarning("Invalid or expired OAuth token supplied.");
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        await context.Response.WriteAsync("Unauthorized: Invalid or Expired OAuth Token");
    }

    private static async Task HandleTokenRequestAsync(HttpContext context)
    {
        var form = await context.Request.ReadFormAsync();
        string clientId = form["client_id"].ToString();
        string clientSecret = form["client_secret"].ToString();
        string grantType = form["grant_type"].ToString();

        if (clientId == OAuthTokenStore.ExpectedClientId &&
            clientSecret == OAuthTokenStore.ExpectedClientSecret &&
            grantType == "client_credentials")
        {
            string accessToken = $"mock_jwt_{Guid.NewGuid():N}";
            OAuthTokenStore.ActiveTokens[accessToken] = DateTime.UtcNow.AddHours(1);

            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new
            {
                access_token = accessToken,
                token_type = "Bearer",
                expires_in = 3600,
                scope = "soap:read soap:write"
            });
            return;
        }

        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        await context.Response.WriteAsJsonAsync(new { error = "invalid_client", error_description = "Invalid client_id or client_secret" });
    }
}