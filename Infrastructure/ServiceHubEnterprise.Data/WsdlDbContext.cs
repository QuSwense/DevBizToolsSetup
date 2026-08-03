using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// EF Core DbContext for the WSDL feature.
/// Owns tables: WsdlRecords, WsdlVersions, WsdlSyncHistory, WsdlTemplates.
/// </summary>
public class WsdlDbContext : DbContext
{
    public WsdlDbContext(DbContextOptions<WsdlDbContext> options) : base(options) { }

    public DbSet<WsdlRecordEntity> WsdlRecords => Set<WsdlRecordEntity>();
    public DbSet<WsdlVersionEntity> WsdlVersions => Set<WsdlVersionEntity>();
    public DbSet<WsdlSyncHistoryEntity> WsdlSyncHistory => Set<WsdlSyncHistoryEntity>();
    public DbSet<WsdlTemplateEntity> WsdlTemplates => Set<WsdlTemplateEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<WsdlRecordEntity>(entity =>
        {
            entity.ToTable("WsdlRecords");
            entity.HasKey(e => e.Id);
        });

        modelBuilder.Entity<WsdlVersionEntity>(entity =>
        {
            entity.ToTable("WsdlVersions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.SyncRecordId);
        });

        modelBuilder.Entity<WsdlSyncHistoryEntity>(entity =>
        {
            entity.ToTable("WsdlSyncHistory");
            entity.HasKey(e => e.Id);
        });

        modelBuilder.Entity<WsdlTemplateEntity>(entity =>
        {
            entity.ToTable("WsdlTemplates");
            entity.HasKey(e => e.Id);
        });
    }
}