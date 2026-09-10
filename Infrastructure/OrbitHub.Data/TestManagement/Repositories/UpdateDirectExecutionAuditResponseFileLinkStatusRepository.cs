using LinqToDB.Data;

namespace OrbitHub.Data.TestManagement.Repositories;

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