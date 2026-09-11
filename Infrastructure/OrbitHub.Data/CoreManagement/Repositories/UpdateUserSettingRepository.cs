using LinqToDB.Data;
using OrbitHub.Data.Common;
using OrbitHub.Data.CoreManagement.Models;

namespace OrbitHub.Data.CoreManagement.Repositories;

public class UpdateUserSettingRepository(CoreDbContext ctx)
{
    private readonly CoreDbContext _ctx = ctx;

    public async Task<RepositoryResult<UpdateUserSettingOutput>> ExecuteAsync(
        UpdateUserSettingInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await _ctx.QueryProcAsync<UpdateUserSettingOutput>(
                "[dbo].[usp_UpdateUserSetting]",
                new DataParameter("@UserSettingId", input.UserSettingId),
                new DataParameter("@GlobalSettingId", input.GlobalSettingId),
                new DataParameter("@SettingValue", input.SettingValue),
                new DataParameter("@UserId", input.UserId)
            )).ToList();

            return RepositoryResult<UpdateUserSettingOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex)
        {
            return RepositoryResult<UpdateUserSettingOutput>.Fail(ex.Message);
        }
    }
}