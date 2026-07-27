var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Add services
builder.Services.AddRazorPages()
    .AddApplicationPart(typeof(SoapApiTest.Pages.IndexModel).Assembly)
    .AddApplicationPart(typeof(RestApiTest.Pages.IndexModel).Assembly)
    .AddApplicationPart(typeof(PdfViewer.Pages.IndexModel).Assembly)
    .AddApplicationPart(typeof(HealthCheck.Pages.IndexModel).Assembly)
    .AddApplicationPart(typeof(Admin.Pages.IndexModel).Assembly);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
