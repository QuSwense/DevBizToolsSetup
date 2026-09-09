namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Non-generic result wrapper for operations that return no data payload.
/// </summary>
public class ResultModel
{
    public bool IsSuccess { get; }
    public string? ErrorMessage { get; }

    protected ResultModel(bool isSuccess, string? errorMessage)
    {
        IsSuccess = isSuccess;
        ErrorMessage = errorMessage;
    }

    public static ResultModel Success() => new(true, null);
    public static ResultModel Failure(string errorMessage) => new(false, errorMessage);
}

/// <summary>
/// Generic result wrapper carrying a strongly-typed data payload.
/// </summary>
/// <typeparam name="T">The data payload type.</typeparam>
public class ResultModel<T> : ResultModel
{
    public T? Data { get; }

    private ResultModel(bool isSuccess, T? data, string? errorMessage) : base(isSuccess, errorMessage) => Data = data;

    public static ResultModel<T> Success(T data) => new(true, data, null);
    public static new ResultModel<T> Failure(string errorMessage) => new(false, default, errorMessage);
}