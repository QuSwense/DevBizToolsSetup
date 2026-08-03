using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// EF Core DbContext for the REST Applications feature.
/// Owns tables: RestApps, RestRequestFiles, RestFileVersions.
/// </summary>
public class RestDbContext : DbContext
{
    public RestDbContext(DbContextOptions<RestDbContext> options) : base(options) { }

    public DbSet<RestAppEntity> RestApps => Set<RestAppEntity>();
    public DbSet<RestRequestFileEntity> RestRequestFiles => Set<RestRequestFileEntity>();
    public DbSet<RestFileVersionEntity> RestFileVersions => Set<RestFileVersionEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<RestAppEntity>(entity =>
        {
            entity.ToTable("RestApps");
            entity.HasKey(e => e.Id);
        });

        modelBuilder.Entity<RestRequestFileEntity>(entity =>
        {
            entity.ToTable("RestRequestFiles");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AppName);
        });

        modelBuilder.Entity<RestFileVersionEntity>(entity =>
        {
            entity.ToTable("RestFileVersions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.FileId);
        });
    }
}