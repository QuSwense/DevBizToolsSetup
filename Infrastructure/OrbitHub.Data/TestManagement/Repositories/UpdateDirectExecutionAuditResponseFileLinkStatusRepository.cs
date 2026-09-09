using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.TestManagement.Models;
using OrbitHub.Data.TestManagement;

namespace OrbitHub.Data.Repositories.TestManagement.Repositories;

public sealed class UpdateDirectExecutionAuditResponseFileLinkStatusRepository(TestDbContext ctx)
{
    public async Task<RepositoryResult> ExecuteAsync(
        UpdateDirectExecutionAuditResponseFileLinkStatusInput input,
        CancellationToken ct = default)
    {
        try
        {
            await ctx.ExecuteAsync(
                "usp_UpdateDirectExecutionAuditResponseFileLinkStatus",
                new DataParameter("@LinkId", input.LinkId),
                new DataParameter("@ExecutionStatus", input.ExecutionStatus),
                new DataParameter("@HttpStatusCode", input.HttpStatusCode),
                new DataParameter("@HttpRequestDurationMs", input.HttpRequestDurationMs),
                new DataParameter("@HttpContentType", input.HttpContentType),
                new DataParameter("@HttpRequestHeaders", input.HttpRequestHeaders),
                new DataParameter("@HttpResponseHeaders", input.HttpResponseHeaders))
            .ConfigureAwait(false);

            return RepositoryResult.CreateSuccess();
        }
        catch (Exception ex)
        {
            return RepositoryResult.CreateFailure(ex);
        }
    }
}