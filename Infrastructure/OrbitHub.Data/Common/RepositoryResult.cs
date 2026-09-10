namespace OrbitHub.Data.Common;

/// <summary>
/// Generic result wrapper for stored procedure executions.
/// </summary>
public class RepositoryResult<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public string? ErrorMessage { get; set; }

    public static RepositoryResult<T> Ok(T data, string? message = null)
        => new() { Success = true, Data = data, Message = message };

    public static RepositoryResult<T> Ok(string message)
        => new() { Success = true, Message = message };

    public static RepositoryResult<T> Fail(string errorMessage)
        => new() { Success = false, ErrorMessage = errorMessage };

    public static RepositoryResult<T> CreateSuccess(T data)
        => new() { Success = true, Data = data };

    public static RepositoryResult<T> CreateFailure(Exception ex)
        => new() { Success = false, ErrorMessage = ex.Message };
}

/// <summary>
/// Non-generic result wrapper for stored procedures that don't return data.
/// </summary>
public class RepositoryResult
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public string? ErrorMessage { get; set; }

    public static RepositoryResult Ok(string? message = null)
        => new() { Success = true, Message = message };

    public static RepositoryResult Fail(string errorMessage)
        => new() { Success = false, ErrorMessage = errorMessage };

    public static RepositoryResult CreateSuccess()
        => new() { Success = true };

    public static RepositoryResult CreateFailure(Exception ex)
        => new() { Success = false, ErrorMessage = ex.Message };
}
