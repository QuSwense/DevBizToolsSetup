using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store for request-file execution history, filtered to SOAP applications.
/// The legacy SoapManagement data model no longer exists, so this implementation reads
/// the current ServiceAppDbContext data when available and otherwise falls back to a safe empty set.
/// </summary>
public class RequestExecutionStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <summary>
    /// All SOAP executions, ordered newest-first.
    /// </summary>
    public SoapExecution[] SoapExecutions
    {
        get
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetService<ServiceAppDbContext>();
                if (db is null)
                    return [];

                var audits = db.DirectExecutionAudits
                    .OrderByDescending(a => a.ExecutedAt)
                    .ToList();

                var links = db.DirectExecutionAuditResponseFileLinks
                    .OrderByDescending(l => l.ExecutedAt)
                    .ToList();

                var fileIds = links.Select(l => l.ServiceRequestFileId).Distinct().ToList();
                var files = db.ServiceRequestFiles
                    .Where(f => fileIds.Contains(f.Id))
                    .Select(f => new { f.Id, f.Name, f.ServiceOperationId })
                    .ToList();

                var operations = db.ServiceOperations
                    .Where(o => files.Select(f => f.ServiceOperationId).Contains(o.Id))
                    .Select(o => new { o.Id, o.OperationName, o.ServiceApplicationId })
                    .ToList();

                var apps = db.ServiceApplications
                    .Where(a => operations.Select(o => o.ServiceApplicationId).Contains(a.Id))
                    .Select(a => new { a.Id, a.Name })
                    .ToDictionary(x => x.Id, x => x.Name);

                var lookup = files.ToDictionary(f => f.Id, f => new
                {
                    f.Name,
                    Operation = operations.FirstOrDefault(o => o.Id == f.ServiceOperationId)?.OperationName ?? "",
                    AppName = operations.FirstOrDefault(o => o.Id == f.ServiceOperationId) is { ServiceApplicationId: var appId } && apps.TryGetValue(appId, out var name)
                        ? name
                        : "Unknown"
                });

                return [.. links
                    .GroupBy(l => l.DirectExecutionAuditId)
                    .Select(g =>
                    {
                        var audit = audits.FirstOrDefault(a => a.Id == g.Key);
                        if (audit is null)
                            return null;

                        var firstLink = g.First();
                        var file = lookup.TryGetValue(firstLink.ServiceRequestFileId, out var fileInfo)
                            ? fileInfo
                            : null;

                        return new SoapExecution(
                            Id: $"ex-{audit.Id}",
                            AppName: file?.AppName ?? "soap",
                            AppType: "soap",
                            FileName: file?.Name ?? audit.Name,
                            Status: firstLink.ExecutionStatus,
                            ExecutedAt: audit.ExecutedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                            DurationMs: (long?)firstLink.HttpRequestDurationMs ?? 0L,
                            TriggeredBy: firstLink.ExecutedBy
                        );
                    })
                    .Where(e => e is not null)
                    .Cast<SoapExecution>()
                    .OrderByDescending(e => e.TryGetTimestamp() ?? DateTime.MinValue)];
            }
            catch
            {
                return [];
            }
        }
    }
}
