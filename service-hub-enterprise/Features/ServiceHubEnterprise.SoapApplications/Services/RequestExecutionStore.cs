using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services;

/// <summary>
/// Singleton store for request-file execution history, filtered to SOAP applications.
/// Reads from the SQLite database via SoapDbContext.
/// </summary>
public class RequestExecutionStore
{
    private readonly IServiceProvider _serviceProvider;

    public RequestExecutionStore(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

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
            return db.SoapExecutionGroups.AsNoTracking()
                .Include(g => g.Files)
                .OrderByDescending(g => g.StartedAt)
                .AsEnumerable()
                .SelectMany(g => g.Files.Select(f => new SoapExecution(
                    Id: $"ex-{g.Id}-{f.FileName}",
                    AppName: f.AppName,
                    AppType: "soap",
                    FileName: f.FileName,
                    Status: f.Status,
                    ExecutedAt: g.StartedAt,
                    DurationMs: g.DurationMs ?? 0,
                    TriggeredBy: g.TriggeredBy
                )))
                .OrderByDescending(e => e.ExecutedAt)
                .ToArray();
        }
    }
}
