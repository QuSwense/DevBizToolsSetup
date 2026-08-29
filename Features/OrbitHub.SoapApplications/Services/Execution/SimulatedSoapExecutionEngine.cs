using System.Text;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using System.Xml.XPath;
using OrbitHub.SoapApplications.Core.Enums;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services.Execution;

/// <summary>
/// Simulated SOAP execution engine. It does not make real network calls; instead
/// it advances each file through the pipeline stages (Queued → BuildingRequest →
/// SendingRequest → AwaitingResponse → ParsingResponse → RunningTestCases →
/// Complete) with a configurable delay, generating deterministic request/response
/// payloads so the UI, parsed-fields and test-case surfaces have real data to show.
/// The execution is modeled as a server-side job: the caller waits through the
/// cycle while progress is reported "as per server update".
/// </summary>
public class SimulatedSoapExecutionEngine(
    SoapAppStore appStore,
    SoapTestCaseStore testCaseStore) : IExecutionEngine
{
    private readonly SoapAppStore _appStore = appStore;
    private readonly SoapTestCaseStore _testCaseStore = testCaseStore;

    /// <summary>
    /// Delay (ms) between stages. The old MockDb:ExecutionStageDelayMs config key was
    /// removed with the mock database; fixed at 500 ms.
    /// </summary>
    private int StageDelayMs => 500;

    /// <inheritdoc />
    public SoapExecutionGroup CreateGroup(IReadOnlyList<SoapRequestFile> files, string triggeredBy)
    {
        var now = DateTime.Now;
        var group = new SoapExecutionGroup
        {
            Id = $"exg-{Guid.NewGuid():N}"[..12],
            StartedAt = FormatTimestamp(now),
            TriggeredBy = triggeredBy,
            Status = "running",
            Files = [.. files.Select(f => new SoapExecutionFile
            {
                FileName = f.FileName,
                AppName = f.AppName,
                Operation = f.ApiPath,
                Status = "queued",
                Stage = ExecutionStage.Queued,
                StagesCompleted = 0,
                StagesTotal = 7,
                RequestContent = f.Content ?? "",
                ResponseMimeType = "text/xml",
                Logs =
                [
                    CreateLog("info", $"Execution queued for '{f.FileName}' (operation '{f.ApiPath}').")
                ]
            })]
        };
        return group;
    }

    /// <inheritdoc />
    public async Task RunAsync(
        SoapExecutionGroup group,
        IProgress<SoapExecutionGroup>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var started = DateTime.Now;
        foreach (var file in group.Files)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await ExecuteFileAsync(group, file, progress, cancellationToken);
        }

        var successCount = group.Files.Count(f => f.Status == "success");
        group.Status = successCount == group.Files.Count
            ? "completed"
            : successCount == 0
                ? "failed"
                : "partial";
        group.FinishedAt = FormatTimestamp(DateTime.Now);
        group.DurationMs = (long)(DateTime.Now - started).TotalMilliseconds;

        progress?.Report(group);
    }

    private async Task ExecuteFileAsync(
        SoapExecutionGroup group,
        SoapExecutionFile file,
        IProgress<SoapExecutionGroup>? progress,
        CancellationToken cancellationToken)
    {
        var started = DateTime.Now;
        file.Status = "running";

        // Guard: files of disabled applications are blocked.
        var app = _appStore.Apps.FirstOrDefault(a => a.Name == file.AppName);
        if (app is not null && app.Status == AppStatus.Disabled)
        {
            FailFile(file, "Application is disabled — execution blocked.");
            progress?.Report(group);
            return;
        }

        // 1. BuildingRequest
        await AdvanceAsync(file, ExecutionStage.BuildingRequest,
            "Building SOAP request envelope.", cancellationToken, progress, group);
        if (string.IsNullOrWhiteSpace(file.RequestContent))
        {
            file.RequestContent = BuildRequestEnvelope(file, app);
        }

        // 2. SendingRequest
        var target = app is not null ? BuildTargetUrl(app) : file.AppName;
        await AdvanceAsync(file, ExecutionStage.SendingRequest,
            $"Sending request to {target}.", cancellationToken, progress, group);

        // 3. AwaitingResponse
        await AdvanceAsync(file, ExecutionStage.AwaitingResponse,
            "Awaiting response from the service...", cancellationToken, progress, group);

        // Deterministic simulated failure hook (for demo/test variety).
        if (IsSimulatedFailure(file))
        {
            FailFile(file, "Simulated service failure (500 Internal Server Error).");
            file.DurationMs = (long)(DateTime.Now - started).TotalMilliseconds;
            progress?.Report(group);
            return;
        }

        // 4. ParsingResponse
        file.ResponseContent = GenerateResponseContent(file);
        file.ParsedFields = ParseFields(file.ResponseContent, "response");
        file.Logs.Add(CreateLog("response", "Response received and parsed."));
        file.Logs.Add(CreateLog("info", $"{file.ParsedFields.Count} field(s) parsed from response."));
        await AdvanceAsync(file, ExecutionStage.ParsingResponse,
            "Parsing response payload.", cancellationToken, progress, group);

        // 5. RunningTestCases
        await AdvanceAsync(file, ExecutionStage.RunningTestCases,
            "Running attached test cases...", cancellationToken, progress, group);
        var testCases = _testCaseStore.GetEnabledForFile(file.AppName, file.FileName);
        file.Extractions = [.. testCases
            .SelectMany(tc => tc.Extractors)
            .Select(ex => EvaluateExtractor(ex, file))];
        if (file.Extractions.Count == 0)
        {
            file.Logs.Add(CreateLog("info", "No test cases attached to this request file."));
        }
        else
        {
            var failed = file.Extractions.Count(x => x.HasExpected && !x.Passed);
            file.Logs.Add(CreateLog("assertion",
                failed == 0
                    ? $"All {file.Extractions.Count} extraction(s) passed."
                    : $"{failed} of {file.Extractions.Count} assertion(s) failed."));
        }

        // 6. Complete
        file.Status = "success";
        file.Stage = ExecutionStage.Complete;
        file.StagesCompleted = file.StagesTotal;
        file.DurationMs = (long)(DateTime.Now - started).TotalMilliseconds;
        file.Logs.Add(CreateLog("info", $"Execution completed in {file.DurationMs} ms."));
        progress?.Report(group);
    }

    private async Task AdvanceAsync(
        SoapExecutionFile file,
        ExecutionStage stage,
        string logMessage,
        CancellationToken cancellationToken,
        IProgress<SoapExecutionGroup>? progress,
        SoapExecutionGroup group)
    {
        await Task.Delay(StageDelayMs, cancellationToken);
        file.Stage = stage;
        file.StagesCompleted = (int)stage;
        file.Logs.Add(CreateLog(stage == ExecutionStage.SendingRequest ? "request" : "info", logMessage));
        progress?.Report(group);
    }

    private void FailFile(SoapExecutionFile file, string reason)
    {
        file.Status = "failed";
        file.Stage = ExecutionStage.Complete;
        file.StagesCompleted = file.StagesTotal;
        file.Logs.Add(CreateLog("error", reason));
    }

    // ── Payload generation (deterministic per file) ──

    private string BuildRequestEnvelope(SoapExecutionFile file, SoapApp? app)
    {
        var ns = $"urn:{(app?.Name ?? file.AppName).ToLowerInvariant().Replace(" ", "")}";
        var requestId = $"req-{StableHash(file.FileName):x8}";
        return $"""
            <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <{file.Operation} xmlns="{ns}">
                  <requestId>{requestId}</requestId>
                  <clientRef>{StableHash(file.FileName) % 1000000:000000}</clientRef>
                </{file.Operation}>
              </soap:Body>
            </soap:Envelope>
            """;
    }

    private string GenerateResponseContent(SoapExecutionFile file)
    {
        var ns = $"urn:{(file.AppName.ToLowerInvariant().Replace(" ", ""))}";
        var status = "Success";
        var responseId = $"resp-{StableHash(file.FileName):x8}";
        var amount = (StableHash(file.FileName) % 90000) + 1000;
        var attachmentText = $"SampleReport for {file.Operation} (batch {StableHash(file.FileName) % 10000:0000}) generated on {DateTime.Today:yyyy-MM-dd}.";
        var attachment = Convert.ToBase64String(Encoding.UTF8.GetBytes(attachmentText));
        return $"""
            <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <{file.Operation}Response xmlns="{ns}">
                  <status>{status}</status>
                  <responseId>{responseId}</responseId>
                  <amount>{amount}</amount>
                  <document>{attachment}</document>
                </{file.Operation}Response>
              </soap:Body>
            </soap:Envelope>
            """;
    }

    private static string BuildTargetUrl(SoapApp app)
    {
        var wsdl = app.WsdlPath ?? "";
        var separator = wsdl.StartsWith('?') ? "" : "?";
        return $"{app.BaseUrl}{separator}{wsdl}";
    }

    private static bool IsSimulatedFailure(SoapExecutionFile file)
    {
        var probe = $"{file.FileName} {file.Operation}";
        return probe.Contains("fail", StringComparison.OrdinalIgnoreCase)
            || probe.Contains("error", StringComparison.OrdinalIgnoreCase);
    }

    // ── Parsed fields ──

    private static List<SoapParsedField> ParseFields(string xml, string source)
    {
        var result = new List<SoapParsedField>();
        try
        {
            var doc = XDocument.Parse(xml);
            foreach (var element in doc.Descendants().Where(e => !e.HasElements))
            {
                var value = element.Value.Trim();
                var path = BuildElementPath(element);
                var isEmbedded = IsLikelyBase64(value);
                result.Add(new SoapParsedField
                {
                    Name = element.Name.LocalName,
                    Source = source,
                    Path = path,
                    Value = value,
                    IsEmbedded = isEmbedded,
                    DecodedPreview = isEmbedded ? DecodePreview(value) : null
                });
            }
        }
        catch
        {
            // Not XML — skip field parsing.
        }
        return result;
    }

    private static string BuildElementPath(XElement element)
    {
        var parts = new List<string>();
        for (var current = element; current is not null; current = current.Parent)
        {
            parts.Add(current.Name.LocalName);
        }
        parts.Reverse();
        return "/" + string.Join("/", parts);
    }

    private static bool IsLikelyBase64(string value)
    {
        if (value.Length < 24 || value.Length % 4 != 0)
            return false;
        if (value.Any(c => !(char.IsAsciiLetterOrDigit(c) || c == '+' || c == '/' || c == '=')))
            return false;
        return value.Contains('=') || value.Length >= 32;
    }

    private static string DecodePreview(string base64)
    {
        try
        {
            var bytes = Convert.FromBase64String(base64);
            var text = Encoding.UTF8.GetString(bytes);
            return text.Length > 200 ? text[..200] + "…" : text;
        }
        catch
        {
            return "(unable to decode)";
        }
    }

    // ── Test-case extraction ──

    private SoapExtractionResult EvaluateExtractor(SoapExtractor extractor, SoapExecutionFile file)
    {
        var sourceContent = extractor.Source == "request" ? file.RequestContent : file.ResponseContent;
        var value = extractor.Type switch
        {
            "xpath" => EvaluateXPath(sourceContent, extractor.Path),
            "jsonpath" => EvaluateJsonPath(sourceContent, extractor.Path),
            "pdf" => EvaluatePdf(file, extractor.Path),
            _ => ""
        };
        var hasExpected = !string.IsNullOrWhiteSpace(extractor.ExpectedValue);
        var passed = !hasExpected
            || string.Equals(value.Trim(), extractor.ExpectedValue!.Trim(), StringComparison.OrdinalIgnoreCase);
        return new SoapExtractionResult
        {
            ExtractorId = extractor.Id,
            Name = extractor.Name,
            Source = extractor.Source,
            Type = extractor.Type,
            Path = extractor.Path,
            Value = value,
            Expected = extractor.ExpectedValue,
            HasExpected = hasExpected,
            Passed = passed
        };
    }

    private static string EvaluateXPath(string content, string path)
    {
        if (string.IsNullOrWhiteSpace(content) || string.IsNullOrWhiteSpace(path))
            return "";
        try
        {
            var doc = XDocument.Parse(content);
            var value = EvaluateXPathValue(doc, path);
            if (string.IsNullOrWhiteSpace(value))
            {
                // Fall back to a local-name match so simple paths like "//status"
                // work even when the document declares a default namespace.
                var localPath = ToLocalNamePath(path);
                if (!string.Equals(localPath, path, StringComparison.Ordinal))
                {
                    value = EvaluateXPathValue(doc, localPath);
                }
            }
            return value;
        }
        catch
        {
            return "";
        }
    }

    private static string EvaluateXPathValue(XDocument doc, string path)
    {
        var value = doc.XPathEvaluate(path);
        return value switch
        {
            string s => s,
            IEnumerable<XElement> els => string.Join(", ", els.Select(e => e.Value)),
            XElement el => el.Value,
            IEnumerable<object> objs => string.Join(", ", objs.Select(ToStringValue)),
            _ => value?.ToString() ?? ""
        };
    }

    /// <summary>
    /// Rewrites unprefixed element steps into local-name predicates so they match
    /// regardless of namespace declarations, e.g. "//status" →
    /// "//*[local-name()='status']". Only used as a fallback.
    /// </summary>
    private static string ToLocalNamePath(string path)
        => Regex.Replace(path, @"([A-Za-z_][\w.-]*)", m => $"*[local-name()='{m.Groups[1].Value}']");

    private static string EvaluateJsonPath(string content, string path)
    {
        if (string.IsNullOrWhiteSpace(content) || string.IsNullOrWhiteSpace(path))
            return "";
        try
        {
            var node = JsonNode.Parse(content);
            var segments = path.TrimStart('$', '.').Split('.', StringSplitOptions.RemoveEmptyEntries);
            JsonNode? current = node;
            foreach (var segment in segments)
            {
                if (current is null) return "";
                if (TryParseIndex(segment, out var index))
                {
                    current = current is JsonArray arr && index < arr.Count ? arr[index] : null;
                }
                else
                {
                    current = current[segment];
                }
            }
            return current is JsonValue v ? v.ToJsonString() : current?.ToJsonString() ?? "";
        }
        catch
        {
            return "";
        }
    }

    private static bool TryParseIndex(string segment, out int index)
    {
        index = -1;
        if (segment.Length >= 3 && segment[0] == '[' && segment[^1] == ']')
        {
            return int.TryParse(segment[1..^1], out index);
        }
        return false;
    }

    /// <summary>
    /// Simulated PDF field extraction. Looks for an embedded base64 payload in the
    /// response, decodes it, and treats <paramref name="path"/> as a field label
    /// (or "text" to return the whole decoded preview). Real PDF parsing is a
    /// later-phase concern (requires a package decision).
    /// </summary>
    private static string EvaluatePdf(SoapExecutionFile file, string path)
    {
        var embedded = file.ParsedFields.FirstOrDefault(f => f.IsEmbedded && f.Source == "response");
        var text = embedded?.DecodedPreview ?? "";
        if (string.IsNullOrWhiteSpace(text))
            return "";
        if (string.Equals(path, "text", StringComparison.OrdinalIgnoreCase))
            return text;
        var line = text.Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .FirstOrDefault(l => l.Contains(path, StringComparison.OrdinalIgnoreCase));
        return line ?? "";
    }

    private static string ToStringValue(object? o) => o switch
    {
        XElement el => el.Value,
        XText text => text.Value,
        XAttribute attr => attr.Value,
        _ => o?.ToString() ?? ""
    };

    // ── Helpers ──

    private static SoapExecutionLog CreateLog(string type, string message) => new()
    {
        Id = $"log-{Guid.NewGuid():N}"[..10],
        Timestamp = FormatTimestamp(DateTime.Now),
        Type = type,
        Message = message
    };

    private static string FormatTimestamp(DateTime value) => value.ToString("yyyy-MM-dd HH:mm:ss");

    /// <summary>Deterministic FNV-1a hash so generated payloads are stable across runs.</summary>
    private static uint StableHash(string input)
    {
        uint hash = 2166136261;
        foreach (var c in input)
        {
            hash ^= c;
            hash *= 16777619;
        }
        return hash;
    }
}
