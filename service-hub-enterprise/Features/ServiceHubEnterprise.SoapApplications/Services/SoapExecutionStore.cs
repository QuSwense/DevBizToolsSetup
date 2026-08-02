using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.Data.Entities;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services;

/// <summary>
/// Singleton store for SOAP execution groups, persisted to the SQLite database
/// via SoapDbContext. Provides LINQ queries over execution groups and their files.
/// </summary>
public class SoapExecutionStore
{
    private readonly IServiceProvider _serviceProvider;

    public SoapExecutionStore(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    /// <summary>All execution groups, newest first.</summary>
    public IReadOnlyList<SoapExecutionGroup> Groups
    {
        get
        {
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            return db.SoapExecutionGroups.AsNoTracking()
                .Include(g => g.Files)
                    .ThenInclude(f => f.Logs)
                .Include(g => g.Files)
                    .ThenInclude(f => f.ParsedFields)
                .Include(g => g.Files)
                    .ThenInclude(f => f.Extractions)
                .OrderByDescending(g => g.StartedAt)
                .AsEnumerable()
                .Select(MapGroup)
                .ToList();
        }
    }

    /// <summary>Returns a single group by id, or null.</summary>
    public SoapExecutionGroup? GetGroup(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entity = db.SoapExecutionGroups.AsNoTracking()
            .Include(g => g.Files)
                .ThenInclude(f => f.Logs)
            .Include(g => g.Files)
                .ThenInclude(f => f.ParsedFields)
            .Include(g => g.Files)
                .ThenInclude(f => f.Extractions)
            .FirstOrDefault(g => g.Id == id);
        return entity is not null ? MapGroup(entity) : null;
    }

    /// <summary>
    /// Returns all groups that executed the given file (across applications),
    /// newest first.
    /// </summary>
    public IReadOnlyList<SoapExecutionGroup> GetGroupsForFile(string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        return db.SoapExecutionGroups.AsNoTracking()
            .Include(g => g.Files)
                .ThenInclude(f => f.Logs)
            .Include(g => g.Files)
                .ThenInclude(f => f.ParsedFields)
            .Include(g => g.Files)
                .ThenInclude(f => f.Extractions)
            .Where(g => g.Files.Any(f => f.FileName == fileName))
            .OrderByDescending(g => g.StartedAt)
            .AsEnumerable()
            .Select(MapGroup)
            .ToList();
    }

    /// <summary>Returns the per-file record for a file within a group, or null.</summary>
    public SoapExecutionFile? GetFile(SoapExecutionGroup group, string fileName) =>
        group.Files.FirstOrDefault(f => f.FileName == fileName);

    /// <summary>Adds a group and persists to the database.</summary>
    public async Task AddGroupAsync(SoapExecutionGroup group)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        db.SoapExecutionGroups.Add(MapGroupToEntity(group));
        await db.SaveChangesAsync();
    }

    /// <summary>Updates an existing group and persists.</summary>
    public async Task UpdateGroupAsync(SoapExecutionGroup group)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var existing = await db.SoapExecutionGroups
            .Include(g => g.Files)
            .FirstOrDefaultAsync(g => g.Id == group.Id);
        if (existing is null) return;

        // Update the group
        existing.Status = group.Status;
        existing.FinishedAt = group.FinishedAt;
        existing.DurationMs = group.DurationMs;

        // Remove old files and re-add
        db.SoapExecutionFiles.RemoveRange(existing.Files);
        existing.Files = MapGroupToEntity(group).Files;

        await db.SaveChangesAsync();
    }

    // ── Mapping helpers ──

    private static SoapExecutionGroup MapGroup(SoapExecutionGroupEntity entity)
    {
        return new SoapExecutionGroup
        {
            Id = entity.Id,
            StartedAt = entity.StartedAt,
            FinishedAt = entity.FinishedAt,
            TriggeredBy = entity.TriggeredBy,
            Status = entity.Status,
            DurationMs = entity.DurationMs ?? 0,
            Files = entity.Files.Select(MapFile).ToList()
        };
    }

    private static SoapExecutionFile MapFile(SoapExecutionFileEntity entity)
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
            Logs = entity.Logs.Select(l => new SoapExecutionLog
            {
                Id = l.Id,
                Timestamp = l.Timestamp,
                Type = l.Type,
                Message = l.Message
            }).ToList(),
            ParsedFields = entity.ParsedFields.Select(p => new SoapParsedField
            {
                Name = p.Name,
                Source = p.Source,
                Path = p.Path,
                Value = p.Value ?? "",
                IsEmbedded = p.IsEmbedded,
                DecodedPreview = p.DecodedPreview ?? ""
            }).ToList(),
            Extractions = entity.Extractions.Select(e => new SoapExtractionResult
            {
                ExtractorId = e.ExtractorId,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                Value = e.Value ?? "",
                Expected = e.Expected ?? "",
                Passed = e.Passed ?? false
            }).ToList()
        };
    }

    private static SoapExecutionGroupEntity MapGroupToEntity(SoapExecutionGroup group)
    {
        return new SoapExecutionGroupEntity
        {
            Id = group.Id,
            StartedAt = group.StartedAt,
            FinishedAt = group.FinishedAt,
            TriggeredBy = group.TriggeredBy,
            Status = group.Status,
            DurationMs = group.DurationMs,
            Files = group.Files.Select(f => new SoapExecutionFileEntity
            {
                Id = $"sef-{Guid.NewGuid():N}"[..12],
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
                ResponseMimeType = f.ResponseMimeType,
                Logs = f.Logs.Select(l => new SoapExecutionLogEntity
                {
                    Id = l.Id,
                    ExecutionFileId = "",
                    Timestamp = l.Timestamp,
                    Type = l.Type,
                    Message = l.Message
                }).ToList(),
                ParsedFields = f.ParsedFields.Select(p => new SoapParsedFieldEntity
                {
                    Id = $"spf-{Guid.NewGuid():N}"[..12],
                    ExecutionFileId = "",
                    Name = p.Name,
                    Source = p.Source,
                    Path = p.Path,
                    Value = p.Value,
                    IsEmbedded = p.IsEmbedded,
                    DecodedPreview = p.DecodedPreview
                }).ToList(),
                Extractions = f.Extractions.Select(e => new SoapExtractionResultEntity
                {
                    Id = $"ser-{Guid.NewGuid():N}"[..12],
                    ExecutionFileId = "",
                    ExtractorId = e.ExtractorId,
                    Name = e.Name,
                    Source = e.Source,
                    Type = e.Type,
                    Path = e.Path,
                    Value = e.Value,
                    Expected = e.Expected,
                    Passed = e.Passed
                }).ToList()
            }).ToList()
        };
    }
}
