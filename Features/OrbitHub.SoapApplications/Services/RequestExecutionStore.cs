using LinqToDB.Async;
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
    private SoapExecution[]? _cached;
    private Task? _loadTask;

    /// <summary>
    /// Returns the cached SOAP executions (never touches the database directly).
    /// Callers must await <see cref="LoadExecutionsAsync"/> first so this renders from the
    /// in-memory cache instead of running synchronous database I/O inside the Blazor renderer.
    /// </summary>
    public SoapExecution[] SoapExecutions => _cached ?? [];

    /// <summary>
    /// Loads (once) and caches the SOAP executions from ServiceAppDbContext.
    /// Safe for concurrent callers — concurrent calls share the same load task.
    /// </summary>
    public Task LoadExecutionsAsync() => _loadTask ??= LoadExecutionsCoreAsync();

    private async Task LoadExecutionsCoreAsync()
    {
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetService<ServiceAppDbContext>();
            if (db is null)
            {
                _cached = [];
                return;
            }

            var audits = await db.DirectExecutionAudits
                .OrderByDescending(a => a.ExecutedAt)
                .ToListAsync();

            var links = await db.DirectExecutionAuditResponseFileLinks
                .OrderByDescending(l => l.ExecutedAt)
                .ToListAsync();

            var fileIds = links.Select(l => l.ServiceRequestFileId).Distinct().ToList();
            var files = await db.ServiceRequestFiles
                .Where(f => fileIds.Contains(f.Id))
                .Select(f => new { f.Id, f.Name, f.ServiceOperationId })
                .ToListAsync();

            var operations = await db.ServiceOperations
                .Where(o => files.Select(f => f.ServiceOperationId).Contains(o.Id))
                .Select(o => new { o.Id, o.OperationName, o.ServiceApplicationId })
                .ToListAsync();

            var apps = await db.ServiceApplications
                .Where(a => operations.Select(o => o.ServiceApplicationId).Contains(a.Id))
                .Select(a => new { a.Id, a.Name })
                .ToListAsync();

            var appsDict = apps.ToDictionary(x => x.Id, x => x.Name);

            var lookup = files.ToDictionary(f => f.Id, f => new
            {
                f.Name,
                Operation = operations.FirstOrDefault(o => o.Id == f.ServiceOperationId)?.OperationName ?? "",
                AppName = operations.FirstOrDefault(o => o.Id == f.ServiceOperationId) is { ServiceApplicationId: var appId } && appsDict.TryGetValue(appId, out var name)
                    ? name
                    : "Unknown"
            });

            _cached = [.. links
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
            // Keep an empty cache and reset the load task so a later refresh retries.
            _cached = [];
            _loadTask = null;
        }
    }
}
