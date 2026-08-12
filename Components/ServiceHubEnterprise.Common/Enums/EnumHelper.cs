// EnumHelper.cs
namespace ServiceHubEnterprise.Common.Enums;

using System.Collections.Concurrent;
using System.Collections.Frozen;
using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using System.Runtime.CompilerServices;

/// <summary>
/// High-performance generic enum helper with lazy-loaded dual maps.
/// Uses FrozenDictionary for O(1) lookups with minimal memory overhead.
/// </summary>
/// <typeparam name="T">The enum type</typeparam>
public static class EnumHelper<T> where T : struct, Enum
{
    // Lazy initialization with thread-safety using LazyThreadSafetyMode.ExecutionAndPublication
    private static readonly Lazy<FrozenDictionary<T, string>> _valueToNameMap = new(
        BuildValueToNameMap,
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    private static readonly Lazy<FrozenDictionary<string, T>> _nameToValueMap = new(
        BuildNameToValueMap,
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    private static readonly Lazy<FrozenDictionary<int, T>> _intToValueMap = new(
        BuildIntToValueMap,
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    // Cache for enum values to avoid repeated Enum.GetValues calls
    private static readonly Lazy<T[]> _enumValues = new(
        () => Enum.GetValues<T>(),
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    // Cache for enum names to avoid repeated Enum.GetNames calls
    private static readonly Lazy<string[]> _enumNames = new(
        () => Enum.GetNames<T>(),
        LazyThreadSafetyMode.ExecutionAndPublication
    );

    static EnumHelper()
    {
        // Ensure enum is valid
        if (!typeof(T).IsEnum)
        {
            throw new InvalidOperationException($"Type {typeof(T).Name} is not an enum.");
        }
    }

    /// <summary>
    /// Gets the string representation of an enum value (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static string GetName(T value) => 
        _valueToNameMap.Value.TryGetValue(value, out var name) 
            ? name 
            : value.ToString();

    /// <summary>
    /// Gets the enum value from its string name (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T GetValue(string name) =>
        _nameToValueMap.Value.TryGetValue(name, out var value) 
            ? value 
            : throw new ArgumentException($"Invalid enum name '{name}' for type {typeof(T).Name}", nameof(name));

    /// <summary>
    /// Tries to get the enum value from its string name (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static bool TryGetValue(string name, [MaybeNullWhen(false)] out T value) =>
        _nameToValueMap.Value.TryGetValue(name, out value);

    /// <summary>
    /// Gets the enum value from its underlying integer value (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T GetValue(int value) =>
        _intToValueMap.Value.TryGetValue(value, out var enumValue) 
            ? enumValue 
            : throw new ArgumentException($"Invalid enum value '{value}' for type {typeof(T).Name}", nameof(value));

    /// <summary>
    /// Tries to get the enum value from its underlying integer value (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static bool TryGetValue(int value, [MaybeNullWhen(false)] out T enumValue) =>
        _intToValueMap.Value.TryGetValue(value, out enumValue);

    /// <summary>
    /// Gets all enum values (cached)
    /// </summary>
    public static IReadOnlyList<T> Values => _enumValues.Value;

    /// <summary>
    /// Gets all enum names (cached)
    /// </summary>
    public static IReadOnlyList<string> Names => _enumNames.Value;

    /// <summary>
    /// Checks if a string is a valid enum name (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static bool IsValidName(string name) =>
        _nameToValueMap.Value.ContainsKey(name);

    /// <summary>
    /// Checks if a value is a valid enum value (O(1) lookup)
    /// </summary>
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static bool IsValidValue(T value) =>
        _valueToNameMap.Value.ContainsKey(value);

    /// <summary>
    /// Gets all enum values with their names as a dictionary
    /// </summary>
    public static IReadOnlyDictionary<T, string> ValueToNameMap => _valueToNameMap.Value;

    /// <summary>
    /// Gets all enum names with their values as a dictionary
    /// </summary>
    public static IReadOnlyDictionary<string, T> NameToValueMap => _nameToValueMap.Value;

    // Build maps using frozen dictionaries for optimal performance
    private static FrozenDictionary<T, string> BuildValueToNameMap()
    {
        var values = _enumValues.Value;
        var names = _enumNames.Value;
        
        // Use dictionary builder for FrozenDictionary
        var builder = new Dictionary<T, string>(values.Length);
        for (int i = 0; i < values.Length; i++)
        {
            builder[values[i]] = names[i];
        }
        
        return builder.ToFrozenDictionary();
    }

    private static FrozenDictionary<string, T> BuildNameToValueMap()
    {
        var values = _enumValues.Value;
        var names = _enumNames.Value;
        
        var builder = new Dictionary<string, T>(values.Length, StringComparer.Ordinal);
        for (int i = 0; i < values.Length; i++)
        {
            builder[names[i]] = values[i];
        }
        
        return builder.ToFrozenDictionary(StringComparer.Ordinal);
    }

    private static FrozenDictionary<int, T> BuildIntToValueMap()
    {
        var values = _enumValues.Value;
        var underlyingType = Enum.GetUnderlyingType(typeof(T));
        
        var builder = new Dictionary<int, T>(values.Length);
        foreach (var value in values)
        {
            // Convert enum value to int safely
            var intValue = Convert.ToInt32(value);
            builder[intValue] = value;
        }
        
        return builder.ToFrozenDictionary();
    }
}