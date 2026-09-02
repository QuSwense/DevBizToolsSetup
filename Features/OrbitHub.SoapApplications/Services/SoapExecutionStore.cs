using LinqToDB;
using LinqToDB.Async;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.SoapApplications.Core.Enums;
using OrbitHub.SoapApplications.Models;
using OrbitHub.Data.SoapManagement;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store for SOAP execution groups, persisted to the database
/// via SoapDbContext. Provides LINQ queries over execution groups and their files.
/// </summary>
public class SoapExecutionStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <summary>All execution groups, newest first.</summary>
    public IReadOnlyList<SoapExecutionGroup> Groups
    {
        get
        {
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            return [.. LoadGroups(db, [.. db.SoapExecutionGroups]).OrderByDescending(g => g.StartedAt)];
        }
    }

    /// <summary>Returns a single group by id, or null.</summary>
    public SoapExecutionGroup? GetGroup(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entity = db.SoapExecutionGroups.FirstOrDefault(g => g.Id == id);
        return entity is not null ? LoadGroups(db, [entity]).FirstOrDefault() : null;
    }

    /// <summary>
    /// Returns all groups that executed the given file (across applications),
    /// newest first.
    /// </summary>
    public IReadOnlyList<SoapExecutionGroup> GetGroupsForFile(string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var groupIds = db.SoapExecutionFiles.Where(f => f.FileName == fileName).Select(f => f.GroupId).Distinct().ToList();
        var groups = db.SoapExecutionGroups.Where(g => groupIds.Contains(g.Id)).ToList();
        return [.. LoadGroups(db, groups).OrderByDescending(g => g.StartedAt)];
    }

    /// <summary>Returns the per-file record for a file within a group, or null.</summary>
    public SoapExecutionFile? GetFile(SoapExecutionGroup group, string fileName) =>
        group.Files.FirstOrDefault(f => f.FileName == fileName);

    /// <summary>Adds a group and persists to the database.</summary>
    public async Task AddGroupAsync(SoapExecutionGroup group)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        await InsertGroupAsync(db, group);
    }

    /// <summary>Updates an existing group and persists.</summary>
    public async Task UpdateGroupAsync(SoapExecutionGroup group)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var existing = await db.SoapExecutionGroups.FirstOrDefaultAsync(g => g.Id == group.Id);
        if (existing is null) return;

        // Update the group
        existing.Status = group.Status;
        existing.FinishedAt = group.FinishedAt;
        existing.DurationMs = group.DurationMs;
        await db.UpdateAsync(existing);

        // Remove old files (cascades to logs/parsed fields/extractions) and re-add
        var fileIds = await db.SoapExecutionFiles.Where(f => f.GroupId == group.Id).Select(f => f.Id).ToListAsync();
        await db.SoapExecutionLogs.Where(l => fileIds.Contains(l.ExecutionFileId)).DeleteAsync();
        await db.SoapParsedFields.Where(p => fileIds.Contains(p.ExecutionFileId)).DeleteAsync();
        await db.SoapExtractionResults.Where(e => fileIds.Contains(e.ExecutionFileId)).DeleteAsync();
        await db.SoapExecutionFiles.Where(f => f.GroupId == group.Id).DeleteAsync();

        await InsertFilesAsync(db, group);
    }

    // ── Mapping helpers ──

    private static IReadOnlyList<SoapExecutionGroup> LoadGroups(SoapDbContext db, IReadOnlyList<SoapExecutionGroupEntity> groups)
    {
        var groupIds = groups.Select(g => g.Id).ToList();
        var filesByGroup = db.SoapExecutionFiles.Where(f => groupIds.Contains(f.GroupId)).ToList().ToLookup(f => f.GroupId);
        var fileIds = filesByGroup.SelectMany(g => g).Select(f => f.Id).ToList();
        var logsByFile = db.SoapExecutionLogs.Where(l => fileIds.Contains(l.ExecutionFileId)).ToList().ToLookup(l => l.ExecutionFileId);
        var parsedByFile = db.SoapParsedFields.Where(p => fileIds.Contains(p.ExecutionFileId)).ToList().ToLookup(p => p.ExecutionFileId);
        var extractionsByFile = db.SoapExtractionResults.Where(e => fileIds.Contains(e.ExecutionFileId)).ToList().ToLookup(e => e.ExecutionFileId);

        return [.. groups.Select(g => new SoapExecutionGroup
        {
            Id = g.Id,
            StartedAt = g.StartedAt,
            FinishedAt = g.FinishedAt,
            TriggeredBy = g.TriggeredBy,
            Status = g.Status,
            DurationMs = g.DurationMs ?? 0,
            Files = [.. filesByGroup[g.Id].Select(f => MapFile(f, logsByFile[f.Id], parsedByFile[f.Id], extractionsByFile[f.Id]))]
        })];
    }

    private static SoapExecutionFile MapFile(
        SoapExecutionFileEntity entity,
        IEnumerable<SoapExecutionLogEntity> logs,
        IEnumerable<SoapParsedFieldEntity> parsedFields,
        IEnumerable<SoapExtractionResultEntity> extractions)
    {
        return new SoapExecutionFile
        {
            FileName = entity.FileName,
            AppName = entity.AppName,
            Operation = entity.Operation,
            Status = entity.Status,
            Stage = (ExecutionStage)entity.Stage,
            StagesCompleted = entity.StagesCompleted,
            StagesTotal = entity.StagesTotal,
            RequestContent = entity.RequestContent ?? "",
            ResponseContent = entity.ResponseContent ?? "",
            ResponseMimeType = entity.ResponseMimeType ?? "",
            Logs = [.. logs.Select(l => new SoapExecutionLog
            {
                Id = l.Id,
                Timestamp = l.Timestamp,
                Type = l.Type,
                Message = l.Message
            })],
            ParsedFields = [.. parsedFields.Select(p => new SoapParsedField
            {
                Name = p.Name,
                Source = p.Source,
                Path = p.Path,
                Value = p.Value ?? "",
                IsEmbedded = p.IsEmbedded,
                DecodedPreview = p.DecodedPreview ?? ""
            })],
            Extractions = [.. extractions.Select(e => new SoapExtractionResult
            {
                ExtractorId = e.ExtractorId,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                Value = e.Value ?? "",
                Expected = e.Expected ?? "",
                Passed = e.Passed ?? false
            })]
        };
    }

    private static async Task InsertGroupAsync(SoapDbContext db, SoapExecutionGroup group)
    {
        await db.InsertAsync(new SoapExecutionGroupEntity
        {
            Id = group.Id,
            StartedAt = group.StartedAt,
            FinishedAt = group.FinishedAt,
            TriggeredBy = group.TriggeredBy,
            Status = group.Status,
            DurationMs = group.DurationMs
        });
        await InsertFilesAsync(db, group);
    }

    private static async Task InsertFilesAsync(SoapDbContext db, SoapExecutionGroup group)
    {
        foreach (var f in group.Files)
        {
            var fileId = $"sef-{Guid.NewGuid():N}"[..12];
            await db.InsertAsync(new SoapExecutionFileEntity
            {
                Id = fileId,
                GroupId = group.Id,
                FileName = f.FileName,
                AppName = f.AppName,
                Operation = f.Operation,
                Status = f.Status,
                Stage = (int)f.Stage,
                StagesCompleted = f.StagesCompleted,
                StagesTotal = f.StagesTotal,
                RequestContent = f.RequestContent,
                ResponseContent = f.ResponseContent,
                ResponseMimeType = f.ResponseMimeType
            });

            foreach (var l in f.Logs)
            {
                await db.InsertAsync(new SoapExecutionLogEntity
                {
                    Id = $"sel-{Guid.NewGuid():N}"[..12],
                    ExecutionFileId = fileId,
                    Timestamp = l.Timestamp,
                    Type = l.Type,
                    Message = l.Message
                });
            }

            foreach (var p in f.ParsedFields)
            {
                await db.InsertAsync(new SoapParsedFieldEntity
                {
                    Id = $"spf-{Guid.NewGuid():N}"[..12],
                    ExecutionFileId = fileId,
                    Name = p.Name,
                    Source = p.Source,
                    Path = p.Path,
                    Value = p.Value,
                    IsEmbedded = p.IsEmbedded,
                    DecodedPreview = p.DecodedPreview
                });
            }

            foreach (var e in f.Extractions)
            {
                await db.InsertAsync(new SoapExtractionResultEntity
                {
                    Id = $"ser-{Guid.NewGuid():N}"[..12],
                    ExecutionFileId = fileId,
                    ExtractorId = e.ExtractorId,
                    Name = e.Name,
                    Source = e.Source,
                    Type = e.Type,
                    Path = e.Path,
                    Value = e.Value,
                    Expected = e.Expected,
                    Passed = e.Passed
                });
            }
        }
    }
}
