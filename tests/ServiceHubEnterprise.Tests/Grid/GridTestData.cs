using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

/// <summary>A simple item type used to exercise the generic ServiceHubGrid.</summary>
public sealed record GridItem(string Id, string Name, int Age, string City);

public static class GridTestData
{
    public static readonly GridItem[] Items =
    [
        new("r1", "Alpha", 30, "Berlin"),
        new("r2", "Beta", 25, "London"),
        new("r3", "Gamma", 40, "Paris"),
        new("r4", "Delta", 22, "Rome"),
        new("r5", "Epsilon", 35, "Madrid")
    ];

    /// <summary>12 items, useful for pagination tests (PageSize 5 → 3 pages).</summary>
    public static readonly GridItem[] ManyItems =
        Enumerable.Range(1, 12).Select(i => new GridItem($"r{i}", $"Item{i}", 20 + i, "City")).ToArray();

    public static List<GridColumn<GridItem>> Columns() =>
    [
        new() { Title = "Name", Field = i => i.Name, Sortable = true },
        new() { Title = "Age", Field = i => i.Age, Sortable = true },
        new() { Title = "City", Field = i => i.City, Sortable = false }
    ];
}
