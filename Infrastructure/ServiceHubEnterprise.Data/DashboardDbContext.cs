using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.Data;

/// <summary>
/// EF Core DbContext for the Dashboard feature.
/// Owns tables: DashboardHealth, DashboardMetrics, Users, UserActivity,
/// ServiceUptime, TestSuites, TestSuiteHistory, RecentActivity.
/// </summary>
public class DashboardDbContext : DbContext
{
    public DashboardDbContext(DbContextOptions<DashboardDbContext> options) : base(options) { }

    public DbSet<DashboardHealthEntity> DashboardHealth => Set<DashboardHealthEntity>();
    public DbSet<DashboardMetricEntity> DashboardMetrics => Set<DashboardMetricEntity>();
    public DbSet<UserEntity> Users => Set<UserEntity>();
    public DbSet<UserActivityEntity> UserActivity => Set<UserActivityEntity>();
    public DbSet<ServiceUptimeEntity> ServiceUptime => Set<ServiceUptimeEntity>();
    public DbSet<TestSuiteEntity> TestSuites => Set<TestSuiteEntity>();
    public DbSet<TestSuiteHistoryEntity> TestSuiteHistory => Set<TestSuiteHistoryEntity>();
    public DbSet<RecentActivityEntity> RecentActivity => Set<RecentActivityEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<DashboardHealthEntity>(entity =>
        {
            entity.ToTable("DashboardHealth");
            entity.HasKey(e => e.Name);
        });

        modelBuilder.Entity<DashboardMetricEntity>(entity =>
        {
            entity.ToTable("DashboardMetrics");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Name).IsUnique();
        });

        modelBuilder.Entity<UserEntity>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(e => e.Name);
        });

        modelBuilder.Entity<UserActivityEntity>(entity =>
        {
            entity.ToTable("UserActivity");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserName);
        });

        modelBuilder.Entity<ServiceUptimeEntity>(entity =>
        {
            entity.ToTable("ServiceUptime");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.ServiceName);
        });

        modelBuilder.Entity<TestSuiteEntity>(entity =>
        {
            entity.ToTable("TestSuites");
            entity.HasKey(e => e.Name);
        });

        modelBuilder.Entity<TestSuiteHistoryEntity>(entity =>
        {
            entity.ToTable("TestSuiteHistory");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.SuiteName);
        });

        modelBuilder.Entity<RecentActivityEntity>(entity =>
        {
            entity.ToTable("RecentActivity");
            entity.HasKey(e => e.Id);
        });
    }
}