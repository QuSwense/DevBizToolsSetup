using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// EF Core DbContext for the File Management feature.
/// Owns tables: FileVersions (generic version snapshots).
/// </summary>
public class FileManagementDbContext : DbContext
{
    public FileManagementDbContext(DbContextOptions<FileManagementDbContext> options) : base(options) { }

    public DbSet<FileVersionEntity> FileVersions => Set<FileVersionEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<FileVersionEntity>(entity =>
        {
            entity.ToTable("FileVersions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.SourceType, e.SourceId });
        });
    }
}