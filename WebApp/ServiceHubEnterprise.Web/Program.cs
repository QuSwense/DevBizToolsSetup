using Microsoft.EntityFrameworkCore;
using ServiceHubEnterprise.Web.Components;
using ServiceHubEnterprise.Dashboard;
using ServiceHubEnterprise.RestApplications;
using ServiceHubEnterprise.SoapApplications;
using ServiceHubEnterprise.FileManagement;
using ServiceHubEnterprise.TestSuite;
using ServiceHubEnterprise.MonitoringHealth;
using ServiceHubEnterprise.ADViewer;
using ServiceHubEnterprise.Settings;
using ServiceHubEnterprise.Data;
using Microsoft.AspNetCore.Mvc.RazorPages;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddRazorPages(options =>
{
    // Discover _Host.cshtml from the Components folder
    options.RootDirectory = "/Components";
});

// ── Database (single SQLite, per-feature DbContexts) ──
var connectionString = ServiceHubDataConfig.GetConnectionString(builder.Configuration);

builder.Services.AddDbContext<SoapDbContext>(opts =>
    opts.UseSqlServer(connectionString));
builder.Services.AddDbContext<RestDbContext>(opts =>
    opts.UseSqlServer(connectionString));
builder.Services.AddDbContext<DashboardDbContext>(opts =>
    opts.UseSqlServer(connectionString));
builder.Services.AddDbContext<WsdlDbContext>(opts =>
    opts.UseSqlServer(connectionString));
builder.Services.AddDbContext<FileManagementDbContext>(opts =>
    opts.UseSqlServer(connectionString));

// Register the DatabaseSeeder (transient — invoked once at startup)
builder.Services.AddTransient<DatabaseSeeder>();

// Register Feature services
builder.Services
    .AddDashboardFeature()
    .AddRestApplicationsFeature()
    .AddSoapApplicationsFeature()
    .AddFileManagementFeature()
    .AddTestSuiteFeature()
    .AddMonitoringHealthFeature()
    .AddADViewerFeature()
    .AddSettingsFeature();

var app = builder.Build();

// ── Seed the database on first run ──
using (var scope = app.Services.CreateScope())
{
    var seeder = scope.ServiceProvider.GetRequiredService<DatabaseSeeder>();
    await seeder.SeedIfEmptyAsync();
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}
app.UseStaticFiles();

app.UseRouting();

app.UseAntiforgery();

app.MapRazorPages();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
