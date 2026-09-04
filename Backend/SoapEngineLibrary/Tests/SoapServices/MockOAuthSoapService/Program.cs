using SoapCore;
using MockOAuthSoapService.Middleware;
using MockOAuthSoapService.Services;

var builder = WebApplication.CreateBuilder(args);

// Register SoapCore & Services
builder.Services.AddSoapCore();
builder.Services.AddScoped<IDocumentSoapService, DocumentSoapService>();

var app = builder.Build();

// Redirect root to WSDL
app.MapGet("/", () => Results.Redirect("/DocumentService.asmx?wsdl"));

// Enable OAuth Middleware
app.UseMiddleware<OAuthAuthMiddleware>();

// Host SOAP Endpoint on /DocumentService.asmx
((IApplicationBuilder)app).UseSoapEndpoint<IDocumentSoapService>(
    path: "/DocumentService.asmx",
    encoder: new SoapEncoderOptions(),
    serializer: SoapSerializer.DataContractSerializer);

// Listen on Port 7051
app.Run("http://localhost:7051");