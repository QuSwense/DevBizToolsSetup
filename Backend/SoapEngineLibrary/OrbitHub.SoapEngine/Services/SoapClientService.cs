using System.Diagnostics;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Xml.Linq;
using Microsoft.Extensions.Logging;
using ServiceHub.SoapEngine.Core.Enums;
using ServiceHub.SoapEngine.Core.Exceptions;
using ServiceHub.SoapEngine.Core.Models.Inputs;
using ServiceHub.SoapEngine.Core.Models.Outputs;

namespace ServiceHub.SoapEngine.Core.Services;

public class SoapClientService(
    HttpClient httpClient,
    SoapEncryptionService encryptionService,
    SoapFileCompressor compressor,
    ILogger<SoapClientService> logger)
{
    public async Task<SoapExecutionResponse> ExecuteAsync(
        string targetUrl,
        string? soapAction,
        byte[] requestBodyBytes,
        bool isCompressed,
        string? encryptedAuthJson,
        EAuthenticationType? authType,
        CancellationToken cancellationToken = default)
    {
        // Validate inputs
        if (string.IsNullOrWhiteSpace(targetUrl))
            throw new ArgumentException("targetUrl must be provided.", nameof(targetUrl));
        if (requestBodyBytes == null || requestBodyBytes.Length == 0)
            throw new ArgumentException("requestBodyBytes must be provided.", nameof(requestBodyBytes));
        if (!string.IsNullOrWhiteSpace(encryptedAuthJson) && !authType.HasValue)
            throw new ArgumentException("authType must be provided when encryptedAuthJson is provided.");
        if (authType.HasValue && string.IsNullOrWhiteSpace(encryptedAuthJson))
            throw new ArgumentException("encryptedAuthJson must be provided when authType is provided.");

        byte[] rawXmlBytes = isCompressed ? compressor.Decompress(requestBodyBytes) : requestBodyBytes;

        using var request = new HttpRequestMessage(HttpMethod.Post, targetUrl);
        request.Content = new ByteArrayContent(rawXmlBytes);
        request.Content.Headers.ContentType = new MediaTypeHeaderValue("text/xml") { CharSet = "utf-8" };

        if (!string.IsNullOrWhiteSpace(soapAction))
            request.Headers.Add("SOAPAction", $"\"{soapAction.Trim('"')}\"");

        if (!string.IsNullOrWhiteSpace(encryptedAuthJson) && authType.HasValue)
            await ApplyAuthenticationAsync(request, encryptedAuthJson, authType.Value, cancellationToken);

        var stopwatch = Stopwatch.StartNew();
        HttpResponseMessage response;
        try
        {
            response = await httpClient.SendAsync(request, cancellationToken);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            logger.LogError(ex, "HTTP transport failure when calling SOAP service at {TargetUrl}", targetUrl);
            throw new SoapHttpException($"Failed to communicate with remote SOAP endpoint: {targetUrl}", HttpStatusCode.ServiceUnavailable, null, targetUrl, ex);
        }
        stopwatch.Stop();

        long latencyMs = stopwatch.ElapsedMilliseconds;
        byte[] responseBytes = await response.Content.ReadAsByteArrayAsync(cancellationToken);
        string responseBody = Encoding.UTF8.GetString(responseBytes);
        int statusCode = (int)response.StatusCode;

        if (!response.IsSuccessStatusCode)
            CheckAndThrowSoapFault(responseBody, response.StatusCode, targetUrl);

        return new SoapExecutionResponse
        {
            HttpStatusCode = statusCode,
            ResponseBody = responseBody,
            RawResponseBytes = responseBytes,
            LatencyMs = latencyMs,
            IsSuccess = response.IsSuccessStatusCode,
            ContentType = response.Content.Headers.ContentType?.MediaType
        };
    }

    private async Task ApplyAuthenticationAsync(
        HttpRequestMessage request,
        string encryptedAuthJson,
        EAuthenticationType authType,
        CancellationToken cancellationToken)
    {
        switch (authType)
        {
            case EAuthenticationType.Basic:
                var basicCreds = encryptionService.DecryptObject<BasicAuthCredentials>(encryptedAuthJson);
                if (basicCreds is not null)
                {
                    string rawToken = $"{basicCreds.Username}:{basicCreds.Password}";
                    string base64Token = Convert.ToBase64String(Encoding.UTF8.GetBytes(rawToken));
                    request.Headers.Authorization = new AuthenticationHeaderValue("Basic", base64Token);
                }
                break;
            case EAuthenticationType.APIKey:
                var apiKeyCreds = encryptionService.DecryptObject<ApiKeyAuthCredentials>(encryptedAuthJson);
                if (apiKeyCreds is not null)
                {
                    if (apiKeyCreds.SendInHeader)
                    {
                        request.Headers.Add(apiKeyCreds.HeaderName, apiKeyCreds.ApiKey);
                    }
                    else
                    {
                        var uriBuilder = new UriBuilder(request.RequestUri!);
                        string queryToAppend = $"{apiKeyCreds.HeaderName}={Uri.EscapeDataString(apiKeyCreds.ApiKey)}";
                        uriBuilder.Query = string.IsNullOrEmpty(uriBuilder.Query)
                            ? queryToAppend
                            : $"{uriBuilder.Query.TrimStart('?')}&{queryToAppend}";
                        request.RequestUri = uriBuilder.Uri;
                    }
                }
                break;
            case EAuthenticationType.OAuth2:
                var oauthCreds = encryptionService.DecryptObject<OAuth2Credentials>(encryptedAuthJson);
                if (oauthCreds is not null)
                {
                    string token = await FetchOAuth2TokenAsync(oauthCreds, cancellationToken);
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                }
                break;
            case EAuthenticationType.NTLM:
                logger.LogWarning("NTLM Auth specified - ensure NetworkCredential provider is configured at the HttpClient handler level.");
                break;
        }
    }

    private async Task<string> FetchOAuth2TokenAsync(OAuth2Credentials creds, CancellationToken cancellationToken)
    {
        using var tokenRequest = new HttpRequestMessage(HttpMethod.Post, creds.TokenEndpoint);
        var dict = new Dictionary<string, string>
        {
            ["grant_type"] = creds.GrantType ?? "client_credentials",
            ["client_id"] = creds.ClientId,
            ["client_secret"] = creds.ClientSecret
        };
        if (!string.IsNullOrWhiteSpace(creds.Scope))
            dict["scope"] = creds.Scope;

        tokenRequest.Content = new FormUrlEncodedContent(dict);
        var tokenResponse = await httpClient.SendAsync(tokenRequest, cancellationToken);
        tokenResponse.EnsureSuccessStatusCode();

        var json = await tokenResponse.Content.ReadAsStringAsync(cancellationToken);
        using var doc = System.Text.Json.JsonDocument.Parse(json);
        if (doc.RootElement.TryGetProperty("access_token", out var tokenProp))
            return tokenProp.GetString() ?? throw new SoapException("OAuth2 token endpoint returned empty access_token.");
        throw new SoapException("OAuth2 token response did not contain 'access_token' field.");
    }

    private static void CheckAndThrowSoapFault(string responseBody, HttpStatusCode statusCode, string targetUrl)
    {
        if (string.IsNullOrWhiteSpace(responseBody))
            throw new SoapHttpException($"HTTP Request failed with status code {statusCode}.", statusCode, responseBody, targetUrl);

        try
        {
            var doc = XDocument.Parse(responseBody);
            var body = doc.Root?.Elements().FirstOrDefault(e => e.Name.LocalName == "Body");
            var fault = body?.Elements().FirstOrDefault(e => e.Name.LocalName == "Fault");
            if (fault is not null)
            {
                string faultCode = fault.Elements().FirstOrDefault(e => e.Name.LocalName == "faultcode" || e.Name.LocalName == "Code")?.Value ?? "Unknown";
                string faultString = fault.Elements().FirstOrDefault(e => e.Name.LocalName == "faultstring" || e.Name.LocalName == "Reason")?.Value ?? "No fault details specified";
                string? faultActor = fault.Elements().FirstOrDefault(e => e.Name.LocalName == "faultactor")?.Value;
                string? detailXml = fault.Elements().FirstOrDefault(e => e.Name.LocalName == "detail")?.ToString();
                throw new SoapFaultException(faultCode, faultString, faultActor, detailXml);
            }
        }
        catch (Exception ex) when (ex is not SoapFaultException)
        {
            // Ignore parsing errors; fall through to generic HTTP exception
        }
        throw new SoapHttpException($"HTTP Request failed with status code {statusCode}.", statusCode, responseBody, targetUrl);
    }
}