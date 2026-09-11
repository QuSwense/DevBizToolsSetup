using OrbitHub.Data.Common;

namespace OrbitHub.Dashboard.Infrastructure.Repositories;

/// <summary>
/// Unwraps the <see cref="RepositoryResult{T}"/> returned by the generated
/// OrbitHub.Data view and stored-procedure repositories.
/// </summary>
internal static class ViewRepositoryResult
{
    /// <summary>
    /// Returns the result payload, or throws when the underlying query failed so the
    /// dashboard page can surface the error through its standard error handling.
    /// </summary>
    public static IReadOnlyList<T> OrThrow<T>(RepositoryResult<List<T>> result)
    {
        if (!result.Success)
        {
            throw new InvalidOperationException(result.ErrorMessage ?? "The dashboard data query failed.");
        }

        return result.Data ?? [];
    }
}
