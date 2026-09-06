using LinqToDB;
using LinqToDB.Data;
using OrbitHub.Data.CoreManagement;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.CoreManagement.Models;

namespace OrbitHub.Data.Repositories.CoreManagement.Repositories;

public class InsertUserActivityRepository(CoreDbContext ctx)
{
    private readonly CoreDbContext _ctx = ctx;

    public async Task<RepositoryResult<InsertUserActivityOutput>> ExecuteAsync(InsertUserActivityInput input, CancellationToken ct = default)
    {
        try
        {
            var result = (await _ctx.QueryProcAsync<InsertUserActivityOutput>(
                "[dbo].[usp_InsertUserActivity]",
                new DataParameter("@UserId", input.UserId),
                new DataParameter("@ActivityType", input.ActivityType),
                new DataParameter("@ActionType", input.ActionType),
                new DataParameter("@FeatureActivitiesJson", input.FeatureActivitiesJson),
                new DataParameter("@RelatedEntityType", input.RelatedEntityType),
                new DataParameter("@RelatedEntityId", input.RelatedEntityId),
                new DataParameter("@Notes", input.Notes)
            )).ToList();

            return RepositoryResult<InsertUserActivityOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex)
        {
            return RepositoryResult<InsertUserActivityOutput>.Fail(ex.Message);
        }
    }
}