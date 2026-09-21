using System;
using System.Runtime.CompilerServices;

namespace OrbitHub.GenericModels;

public static class Guard
{
    public static string NotNullOrWhiteSpace(this string value, [CallerArgumentExpression(nameof(value))] string? name = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value, name);
        return value;
    }
}