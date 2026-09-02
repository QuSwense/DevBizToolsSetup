using Microsoft.Extensions.DependencyInjection;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store for request-file execution history, filtered to SOAP applications.
/// Reads from the database via SoapDbContext.
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
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            // SoapExecution data comes from the execution groups
            var groups = db.SoapExecutionGroups.ToList();
            var filesByGroup = db.SoapExecutionFiles.ToList().ToLookup(f => f.GroupId);

            return [.. groups
                .SelectMany(g => filesByGroup[g.Id].Select(f => new SoapExecution(
                    Id: $"ex-{g.Id}-{f.FileName}",
                    AppName: f.AppName,
                    AppType: "soap",
                    FileName: f.FileName,
                    Status: f.Status,
                    ExecutedAt: g.StartedAt,
                    DurationMs: g.DurationMs ?? 0,
                    TriggeredBy: g.TriggeredBy
                )))
                .OrderByDescending(e => e.ExecutedAt)];
        }
    }
}
