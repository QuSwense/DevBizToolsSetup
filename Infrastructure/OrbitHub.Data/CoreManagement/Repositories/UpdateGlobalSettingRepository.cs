using LinqToDB.Data;
using OrbitHub.Data.CoreManagement;
using OrbitHub.Data.Repositories.Common;
using OrbitHub.Data.Repositories.CoreManagement.Models;

namespace OrbitHub.Data.Repositories.CoreManagement.Repositories;

public class UpdateGlobalSettingRepository(CoreDbContext ctx)
{
    private readonly CoreDbContext _ctx = ctx;

    public async Task<RepositoryResult<UpdateGlobalSettingOutput>> ExecuteAsync(
        UpdateGlobalSettingInput input,
        CancellationToken ct = default)
    {
        try
        {
            var result = (await _ctx.QueryProcAsync<UpdateGlobalSettingOutput>(
                "[dbo].[usp_UpdateGlobalSetting]",
                new DataParameter("@GlobalSettingId", input.GlobalSettingId),
                new DataParameter("@Category", input.Category),
                new DataParameter("@SettingKey", input.SettingKey),
                new DataParameter("@SettingValue", input.SettingValue),
                new DataParameter("@DataType", input.DataType),
                new DataParameter("@Description", input.Description),
                new DataParameter("@IsUserOverridable", input.IsUserOverridable),
                new DataParameter("@IsActive", input.IsActive),
                new DataParameter("@UserId", input.UserId)
            )).ToList();

            return RepositoryResult<UpdateGlobalSettingOutput>.Ok(result.FirstOrDefault()!);
        }
        catch (Exception ex)
        {
            return RepositoryResult<UpdateGlobalSettingOutput>.Fail(ex.Message);
        }
    }
}