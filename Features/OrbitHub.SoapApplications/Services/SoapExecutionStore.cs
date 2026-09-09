using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// In-memory store for SOAP execution groups.
/// The legacy SoapManagement tables were removed from the generated data model,
/// so this implementation keeps the established public API while operating over the
/// feature's runtime model without changing the Razor pages.
/// </summary>
public class SoapExecutionStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private readonly List<SoapExecutionGroup> _groups = [];

    /// <summary>All execution groups, newest first.</summary>
    public IReadOnlyList<SoapExecutionGroup> Groups => [.. _groups.OrderByDescending(g => ParseDate(g.StartedAt))];

    /// <summary>Returns a single group by id, or null.</summary>
    public SoapExecutionGroup? GetGroup(string id) => _groups.FirstOrDefault(g => g.Id == id);

    /// <summary>
    /// Returns all groups that executed the given file (across applications),
    /// newest first.
    /// </summary>
    public IReadOnlyList<SoapExecutionGroup> GetGroupsForFile(string fileName)
        => [.. _groups.Where(g => g.Files.Any(f => f.FileName == fileName)).OrderByDescending(g => ParseDate(g.StartedAt))];

    /// <summary>Returns the per-file record for a file within a group, or null.</summary>
    public SoapExecutionFile? GetFile(SoapExecutionGroup group, string fileName) =>
        group.Files.FirstOrDefault(f => f.FileName == fileName);

    /// <summary>Adds a group and persists to the in-memory catalog.</summary>
    public Task AddGroupAsync(SoapExecutionGroup group)
    {
        _groups.RemoveAll(g => g.Id == group.Id);
        _groups.Add(group);
        return Task.CompletedTask;
    }

    /// <summary>Updates an existing group in memory.</summary>
    public Task UpdateGroupAsync(SoapExecutionGroup group)
    {
        var index = _groups.FindIndex(g => g.Id == group.Id);
        if (index >= 0)
            _groups[index] = group;
        else
            _groups.Add(group);

        return Task.CompletedTask;
    }

    private static DateTime ParseDate(string value)
        => DateTime.TryParse(value, out var dt) ? dt : DateTime.MinValue;
}
