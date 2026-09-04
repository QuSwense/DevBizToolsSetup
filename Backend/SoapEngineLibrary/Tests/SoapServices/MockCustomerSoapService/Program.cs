using SoapCore;
using MockCustomerSoapService.Middleware;
using MockCustomerSoapService.Services;

var builder = WebApplication.CreateBuilder(args);

// Register SoapCore & Application Services
builder.Services.AddSoapCore();
builder.Services.AddScoped<ICustomerSoapService, CustomerSoapService>();

var app = builder.Build();

// Enable Basic Auth Middleware
app.UseMiddleware<BasicAuthMiddleware>();

// Fix for CS0121: Explicitly pass arguments using named parameters
((IApplicationBuilder)app).UseSoapEndpoint<ICustomerSoapService>(
    path: "/CustomerService.asmx",
    encoder: new SoapEncoderOptions(),
    serializer: SoapSerializer.DataContractSerializer);

app.Run("http://localhost:7050");