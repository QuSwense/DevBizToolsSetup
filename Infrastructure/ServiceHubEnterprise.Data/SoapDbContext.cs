using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// EF Core DbContext for the SOAP Applications feature.
/// Owns tables: SoapApps, SoapApis, SoapRequestFiles, SoapFileVersions,
/// SoapExecutionGroups, SoapExecutionFiles, SoapExecutionLogs, SoapParsedFields,
/// SoapExtractionResults, SoapTestCases, SoapExtractors.
/// </summary>
public class SoapDbContext : DbContext
{
    public SoapDbContext(DbContextOptions<SoapDbContext> options) : base(options) { }

    public DbSet<SoapAppEntity> SoapApps => Set<SoapAppEntity>();
    public DbSet<SoapApiEntity> SoapApis => Set<SoapApiEntity>();
    public DbSet<SoapRequestFileEntity> SoapRequestFiles => Set<SoapRequestFileEntity>();
    public DbSet<SoapRequestFileTestCaseEntity> SoapRequestFileTestCases => Set<SoapRequestFileTestCaseEntity>();
    public DbSet<SoapExecutionGroupEntity> SoapExecutionGroups => Set<SoapExecutionGroupEntity>();
    public DbSet<SoapExecutionFileEntity> SoapExecutionFiles => Set<SoapExecutionFileEntity>();
    public DbSet<SoapExecutionLogEntity> SoapExecutionLogs => Set<SoapExecutionLogEntity>();
    public DbSet<SoapParsedFieldEntity> SoapParsedFields => Set<SoapParsedFieldEntity>();
    public DbSet<SoapExtractionResultEntity> SoapExtractionResults => Set<SoapExtractionResultEntity>();
    public DbSet<SoapTestCaseEntity> SoapTestCases => Set<SoapTestCaseEntity>();
    public DbSet<SoapExtractorEntity> SoapExtractors => Set<SoapExtractorEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<SoapAppEntity>(entity =>
        {
            entity.ToTable("SoapApps");
            entity.HasKey(e => e.Id);
            entity.HasMany(e => e.Apis)
                  .WithOne()
                  .HasForeignKey(e => e.AppId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SoapApiEntity>(entity =>
        {
            entity.ToTable("SoapApis");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AppId);
        });

        modelBuilder.Entity<SoapRequestFileEntity>(entity =>
        {
            entity.ToTable("SoapRequestFiles");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AppName);
            entity.HasIndex(e => e.FileName);
        });

        modelBuilder.Entity<SoapRequestFileTestCaseEntity>(entity =>
        {
            entity.ToTable("SoapRequestFileTestCases");
            entity.HasKey(e => new { e.FileId, e.TestCaseId });
            entity.HasIndex(e => e.FileId);
            entity.HasIndex(e => e.TestCaseId);
        });

        modelBuilder.Entity<SoapExecutionGroupEntity>(entity =>
        {
            entity.ToTable("SoapExecutionGroups");
            entity.HasKey(e => e.Id);
            entity.HasMany(e => e.Files)
                  .WithOne()
                  .HasForeignKey(e => e.GroupId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SoapExecutionFileEntity>(entity =>
        {
            entity.ToTable("SoapExecutionFiles");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.GroupId);
            entity.HasMany(e => e.Logs)
                  .WithOne()
                  .HasForeignKey(e => e.ExecutionFileId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.ParsedFields)
                  .WithOne()
                  .HasForeignKey(e => e.ExecutionFileId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(e => e.Extractions)
                  .WithOne()
                  .HasForeignKey(e => e.ExecutionFileId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SoapExecutionLogEntity>(entity =>
        {
            entity.ToTable("SoapExecutionLogs");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.ExecutionFileId);
        });

        modelBuilder.Entity<SoapParsedFieldEntity>(entity =>
        {
            entity.ToTable("SoapParsedFields");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.ExecutionFileId);
        });

        modelBuilder.Entity<SoapExtractionResultEntity>(entity =>
        {
            entity.ToTable("SoapExtractionResults");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.ExecutionFileId);
        });

        modelBuilder.Entity<SoapTestCaseEntity>(entity =>
        {
            entity.ToTable("SoapTestCases");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.AppName, e.FileName });
            entity.HasMany(e => e.Extractors)
                  .WithOne()
                  .HasForeignKey(e => e.TestCaseId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SoapExtractorEntity>(entity =>
        {
            entity.ToTable("SoapExtractors");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TestCaseId);
        });
    }
}