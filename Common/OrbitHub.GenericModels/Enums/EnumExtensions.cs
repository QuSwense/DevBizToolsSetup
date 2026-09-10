// EnumExtensions.cs
namespace OrbitHub.GenericModels.Enums;

using System.Runtime.CompilerServices;

/// <summary>
/// Static extension methods for enum types that delegate to the cached
/// <see cref="EnumHelper{T}"/> maps for O(1) name lookups.
/// </summary>
public static class EnumExtensions
{
    /// <summary>
    /// Returns the cached string name of an enum value (O(1) lookup).
    /// </summary>
    /// <example>
    /// <code>
    /// var name = MyEnum.Value.ToStringCached();
    /// </code>
    /// </example>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static string ToStringCached<T>(this T value) where T : struct, Enum
        => EnumHelper<T>.GetName(value);

    /// <summary>
    /// Returns the cached string name of a nullable enum value,
    /// or <c>null</c> if the value is <c>null</c>.
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static string? ToStringCached<T>(this T? value) where T : struct, Enum
        => value.HasValue ? EnumHelper<T>.GetName(value.Value) : null;
}