using LinqToDB.Async;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Executions;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Executions;

/// <summary>
/// Reads the request-file execution history from the MSSQL database through linq2db.
/// Executions are the direct execution audits joined to their request file and application.
/// </summary>
internal sealed class DashboardExecutionsRepository(IServiceProvider serviceProvider) : IDashboardExecutionsRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestExecutionEntity>> GetRequestExecutionsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ServiceAppDbContext>();

        var audits = await db.DirectExecutionAudits.ToListAsync();
        var firstLinkByAudit = (await db.DirectExecutionAuditResponseFileLinks.ToListAsync())
            .GroupBy(l => l.DirectExecutionAuditId)
            .ToDictionary(g => g.Key, g => g.First());
        var files = (await db.ServiceRequestFiles.ToListAsync()).ToDictionary(f => f.Id);
        var operations = (await db.ServiceOperations.ToListAsync()).ToDictionary(o => o.Id);
        var apps = (await db.ServiceApplications.ToListAsync()).ToDictionary(a => a.Id);

        return [.. audits
            .Select(a =>
            {
                ServiceRequestFile? file = null;
                ServiceOperation? operation = null;
                ServiceApplication? app = null;

                if (firstLinkByAudit.TryGetValue(a.Id, out var link))
                {
                    file = files.GetValueOrDefault(link.ServiceRequestFileId);
                    operation = file is null ? null : operations.GetValueOrDefault(file.ServiceOperationId);
                    app = operation is null ? null : apps.GetValueOrDefault(operation.ServiceApplicationId);
                }

                var durationMs = a.ExecutionCompletedAt is { } end
                    ? (int)(end - a.ExecutedAt).TotalMilliseconds
                    : 0;

                return new RequestExecutionEntity
                {
                    Id = a.Id.ToString(),
                    AppName = app?.Name ?? "",
                    AppType = app?.ServiceType ?? "",
                    FileName = file?.Name ?? a.Name,
                    Status = a.ExecutionStatus,
                    ExecutedAt = a.ExecutedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                    DurationMs = Math.Max(durationMs, 0),
                    TriggeredBy = a.ExecutedBy
                };
            })
            .OrderByDescending(e => e.ExecutedAt)];
    }
}
