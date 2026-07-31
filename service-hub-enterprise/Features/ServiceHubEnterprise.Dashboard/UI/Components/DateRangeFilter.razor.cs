using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.UI.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the DateRangeFilter dialog.
/// Provides preset date ranges plus custom start/end date inputs.
/// </summary>
public partial class DateRangeFilter
{
    /// <summary>
    /// Represents a selectable preset date range.
    /// </summary>
    public record Preset(string Label, int Days);

    /// <summary>
    /// Gets or sets the currently applied date range.
    /// </summary>
    [Parameter] public DateRange? Value { get; set; }

    /// <summary>
    /// Invoked when the user applies or clears a date range.
    /// </summary>
    [Parameter] public EventCallback<DateRange?> ValueChanged { get; set; }

    private DateTime? _startValue;
    private DateTime? _endValue;

    /// <inheritdoc />
    protected override void OnParametersSet()
    {
        _startValue = Value?.Start;
        _endValue = Value?.End;
    }

    private static readonly IReadOnlyList<Preset> Presets = new[]
    {
        new Preset("7d", 7),
        new Preset("14d", 14),
        new Preset("30d", 30),
        new Preset("90d", 90),
        new Preset("All", 0)
    };

    private bool IsPresetActive(Preset preset)
    {
        if (preset.Days == 0)
        {
            return Value?.IsAll == true;
        }

        var expected = DateRange.LastDays(preset.Days);
        return Value?.Start == expected.Start && Value?.End == expected.End;
    }

    private void ApplyPreset(Preset preset)
    {
        var range = preset.Days == 0 ? DateRange.All : DateRange.LastDays(preset.Days);
        _startValue = range.Start;
        _endValue = range.End;
        _ = ValueChanged.InvokeAsync(range);
    }

    private void Apply()
    {
        _ = ValueChanged.InvokeAsync(new DateRange(_startValue, _endValue));
    }

    private void Clear()
    {
        _startValue = null;
        _endValue = null;
        _ = ValueChanged.InvokeAsync(DateRange.All);
    }
}
