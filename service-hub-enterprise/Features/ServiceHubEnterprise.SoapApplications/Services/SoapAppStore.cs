using System.Text.RegularExpressions;

namespace ServiceHubEnterprise.SoapApplications.Services;

public class SoapApiEntry
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
}

public record SoapApp(string Id, string Name, string BaseUrl, string WsdlPath, string Description, string Status, string UpdatedBy, string CreatedDate, int ApisCount, string AuthType, string AuthUsername, string AuthPassword, string AuthExtra, SoapApiEntry[] Apis);

/// <summary>
/// Singleton store that holds the SOAP application data,
/// shared between Applications.razor and RequestFiles.razor.
/// </summary>
public class SoapAppStore
{
    public SoapApp[] Apps { get; private set; }

    public SoapAppStore()
    {
        Apps = GetSeedData();
    }

    public void UpdateApps(SoapApp[] apps)
    {
        Apps = apps;
    }

    private static SoapApp[] GetSeedData()
    {
        return
        [
            new("s1", "LegacyBilling", "https://soap.billing.com/BillingService", "?singlewsdl", "Enterprise billing service", "enabled", "Suresh Kumar", "2023-08-12", 3, "basic", "billing_user", "", "", [new SoapApiEntry { Name = "SubmitInvoice", Description = "Submit billing invoices" }, new SoapApiEntry { Name = "GetInvoiceStatus", Description = "Check invoice status" }, new SoapApiEntry { Name = "GenerateReport", Description = "Generate billing reports" }]),
            new("s2", "ShippingSOAP", "https://soap.shipping.com/ShipService", "?singlewsdl", "Global shipping and tracking", "disabled", "Priya Sharma", "2023-09-01", 2, "basic", "shipping_admin", "", "", [new SoapApiEntry { Name = "TrackShipment", Description = "Track package location" }, new SoapApiEntry { Name = "CreateLabel", Description = "Generate shipping labels" }]),
            new("s3", "CustomerPortal", "https://soap.customer.com/PortalService", "?singlewsdl", "Customer self-service portal", "enabled", "Anita Desai", "2023-07-05", 5, "basic", "portal_api", "", "", [new SoapApiEntry { Name = "GetProfile", Description = "Fetch customer profile" }, new SoapApiEntry { Name = "UpdateProfile", Description = "Update customer details" }, new SoapApiEntry { Name = "GetOrders", Description = "List customer orders" }, new SoapApiEntry { Name = "SubmitTicket", Description = "Submit support ticket" }, new SoapApiEntry { Name = "GetTicketStatus", Description = "Check ticket status" }]),
            new("s4", "InventorySync", "https://soap.inventory.com/SyncService", "?singlewsdl", "Real-time inventory sync", "disabled", "Vikram Singh", "2024-01-15", 1, "api-key", "sync_user", "sk-sync-abc123", "", [new SoapApiEntry { Name = "SyncInventory", Description = "Synchronize inventory data" }]),
            new("s5", "PaymentGateway", "https://soap.payment.com/Gateway", "?singlewsdl", "Payment processing gateway", "enabled", "Priya Sharma", "2023-11-20", 4, "bearer", "", "eyJhbGciOiJIUzI1NiJ9.eyJ...", "", [new SoapApiEntry { Name = "ProcessPayment", Description = "Process customer payment" }, new SoapApiEntry { Name = "RefundTransaction", Description = "Issue refund" }, new SoapApiEntry { Name = "GetTransactionLog", Description = "Retrieve transaction log" }, new SoapApiEntry { Name = "ValidateCard", Description = "Validate credit card" }]),
            new("s6", "OrderProcessing", "https://soap.orders.com/OrderService", "?singlewsdl", "Order management system", "enabled", "Rahul Patel", "2024-03-10", 6, "ntlm", "ORDERS\\svc_order", "p@ssw0rd", "ORDERS", [new SoapApiEntry { Name = "CreateOrder", Description = "Create new order" }, new SoapApiEntry { Name = "CancelOrder", Description = "Cancel existing order" }, new SoapApiEntry { Name = "GetOrderDetails", Description = "Get order details" }, new SoapApiEntry { Name = "UpdateOrderStatus", Description = "Update order status" }, new SoapApiEntry { Name = "ListOrders", Description = "List all orders" }, new SoapApiEntry { Name = "GetOrderHistory", Description = "Get order history" }]),
            new("s7", "NotificationHub", "https://soap.notify.com/NotifyService", "?singlewsdl", "Centralized notification service", "enabled", "Suresh Kumar", "2024-02-28", 3, "none", "", "", "", [new SoapApiEntry { Name = "SendEmail", Description = "Send email notification" }, new SoapApiEntry { Name = "SendSms", Description = "Send SMS notification" }, new SoapApiEntry { Name = "GetDeliveryStatus", Description = "Check delivery status" }]),
            new("s8", "ReportingEngine", "https://soap.report.com/ReportService", "?singlewsdl", "Business reporting engine", "disabled", "Anita Desai", "2023-10-12", 2, "basic", "report_user", "", "", [new SoapApiEntry { Name = "GenerateReport", Description = "Generate business report" }, new SoapApiEntry { Name = "ExportReport", Description = "Export report as file" }])
        ];
    }
}

// ── WSDL Sync Models ──

/// <summary>
/// Represents a WSDL sync record linking a SOAP application to its WSDL source.
/// </summary>
public class WsdlSyncRecord
{
    public string Id { get; set; } = "";
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "";
    public string SourceType { get; set; } = "url"; // "url" | "upload"
    public string SourceUrl { get; set; } = "";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "synced"; // "synced" | "failed" | "parsing"
    public string WsdlContent { get; set; } = "";
    public int VersionCount { get; set; } = 1;
}

/// <summary>
/// A specific version snapshot of a WSDL sync record.
/// </summary>
public class WsdlVersionEntry
{
    public string Id { get; set; } = "";
    public string SyncRecordId { get; set; } = "";
    public int VersionNumber { get; set; } = 1;
    public string Label { get; set; } = "v1";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "active"; // "active" | "archived"
    public string Notes { get; set; } = "";
}

/// <summary>
/// A template for generating SOAP request files with {{var_name}} placeholders.
/// A template can extend another template to inherit its content and variables.
/// </summary>
public class WsdlTemplate
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string Content { get; set; } = "";
    public string? ExtendsTemplateId { get; set; }
    public string? ExtendsTemplateName { get; set; }
    public string[] Variables { get; set; } = [];
    public string CreatedBy { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public string UpdatedAt { get; set; } = "";
    public int UsageCount { get; set; } = 0;
}

/// <summary>
/// Describes a variable extracted from a template for the dynamic form.
/// </summary>
public class TemplateVariableDef
{
    public string Name { get; set; } = "";
    public string Label { get; set; } = "";
    public string DefaultValue { get; set; } = "";
    public string InputType { get; set; } = "text"; // "text" | "textarea" | "select"
    public string[] Options { get; set; } = [];
}

/// <summary>
/// Singleton store for WSDL sync records, versions, and templates.
/// </summary>
public class WsdlSyncStore
{
    public List<WsdlSyncRecord> Records { get; private set; }
    public List<WsdlVersionEntry> Versions { get; private set; }
    public List<WsdlTemplate> Templates { get; private set; }

    public WsdlSyncStore()
    {
        var seed = GetSeedData();
        Records = seed.Records;
        Versions = seed.Versions;
        Templates = seed.Templates;
    }

    public WsdlSyncRecord[] GetRecordsForApp(string appId) =>
        Records.Where(r => r.AppId == appId).OrderByDescending(r => r.UploadedAt).ToArray();

    public WsdlVersionEntry[] GetVersionsForSync(string syncId) =>
        Versions.Where(v => v.SyncRecordId == syncId).OrderByDescending(v => v.VersionNumber).ToArray();

    public WsdlTemplate[] GetTemplates() => Templates.OrderBy(t => t.Name).ToArray();

    public WsdlTemplate? GetTemplate(string id) => Templates.FirstOrDefault(t => t.Id == id);

    public WsdlTemplate? ResolveEffectiveTemplate(WsdlTemplate template)
    {
        if (string.IsNullOrEmpty(template.ExtendsTemplateId))
            return template;
        return GetTemplate(template.ExtendsTemplateId);
    }

    /// <summary>
    /// Resolves all variables for a template, including inherited ones from parent templates.
    /// </summary>
    public TemplateVariableDef[] ResolveVariables(WsdlTemplate template)
    {
        var allVars = new List<TemplateVariableDef>();
        var seen = new HashSet<string>();

        // Walk the inheritance chain
        var current = template;
        while (current != null)
        {
            foreach (var varName in current.Variables)
            {
                if (seen.Add(varName))
                {
                    allVars.Add(new TemplateVariableDef
                    {
                        Name = varName,
                        Label = ToLabel(varName),
                        DefaultValue = "",
                        InputType = "text"
                    });
                }
            }
            current = string.IsNullOrEmpty(current.ExtendsTemplateId)
                ? null
                : GetTemplate(current.ExtendsTemplateId);
        }

        return allVars.ToArray();
    }

    /// <summary>
    /// Parses WSDL content to extract variable names between XML tags or in attribute values.
    /// Only looks into values between opening/closing tags and attribute values.
    /// </summary>
    public static string[] ParseWsdlVariables(string wsdlContent)
    {
        if (string.IsNullOrWhiteSpace(wsdlContent))
            return [];

        var vars = new HashSet<string>();

        // Match content between XML tags: <tag>value</tag>
        var tagContentMatches = Regex.Matches(wsdlContent, @">([^<]+)<");
        foreach (Match m in tagContentMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        // Match attribute values: name="value" or name='value'
        var attrValueMatches = Regex.Matches(wsdlContent, @"=\s*""([^""]*)""");
        foreach (Match m in attrValueMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        var attrValueSingleMatches = Regex.Matches(wsdlContent, @"=\s*'([^']*)'");
        foreach (Match m in attrValueSingleMatches)
        {
            var content = m.Groups[1].Value.Trim();
            if (content.Length > 0 && content.Length < 200)
                AddVariablesFromText(content, vars);
        }

        return vars.OrderBy(v => v).ToArray();
    }

    private static void AddVariablesFromText(string text, HashSet<string> vars)
    {
        if (string.IsNullOrWhiteSpace(text)) return;

        var candidates = text.Split([' ', '\t', '\n', '\r', ',', ';'], StringSplitOptions.RemoveEmptyEntries);
        foreach (var candidate in candidates)
        {
            var trimmed = candidate.Trim('.', '!', '?', ':');
            if (trimmed.Length > 1 && !int.TryParse(trimmed, out _) &&
                !trimmed.All(c => char.IsPunctuation(c)))
            {
                var suggested = ToVariableName(trimmed);
                if (!string.IsNullOrEmpty(suggested))
                    vars.Add(suggested);
            }
        }
    }

    /// <summary>
    /// Converts arbitrary text to a {{var_name}} compatible variable name.
    /// </summary>
    public static string ToVariableName(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";
        var cleaned = Regex.Replace(text, @"[^a-zA-Z0-9\s]", " ");
        var parts = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "";
        return string.Join("_", parts.Select(p => p.ToLower())).Trim('_');
    }

    /// <summary>
    /// Converts a variable name like "customer_id" to a display label like "Customer ID".
    /// </summary>
    public static string ToLabel(string varName)
    {
        if (string.IsNullOrWhiteSpace(varName)) return "";
        return string.Join(" ", varName.Split('_').Select(w =>
            w.Length > 0 ? char.ToUpper(w[0]) + w[1..] : w));
    }

    /// <summary>
    /// Applies {{var_name}} substitutions to a template content string.
    /// Only supports simple variable paths like {{var_name}}, no complex paths.
    /// </summary>
    public static string ApplyVariables(string content, Dictionary<string, string> values)
    {
        if (string.IsNullOrWhiteSpace(content) || values == null || values.Count == 0)
            return content;

        return Regex.Replace(content, @"\{\{(\w+)\}\}", match =>
        {
            var varName = match.Groups[1].Value;
            return values.TryGetValue(varName, out var val) ? val : match.Value;
        });
    }

    // ── Sample WSDL content for seed data ──

    private const string SampleWsdlBasic = @"<wsdl:definitions xmlns:wsdl=""http://schemas.xmlsoap.org/wsdl/"" xmlns:soap=""http://schemas.xmlsoap.org/wsdl/soap/"" xmlns:tns=""http://example.com/billing"" targetNamespace=""http://example.com/billing"">
  <wsdl:types>
    <schema xmlns=""http://www.w3.org/2001/XMLSchema"">
      <element name=""GetUserRequest""><complexType><sequence><element name=""Id"" type=""string""/></sequence></complexType></element>
      <element name=""GetUserResponse""><complexType><sequence><element name=""User"" type=""string""/></sequence></complexType></element>
      <element name=""UpdateUserRequest""><complexType><sequence><element name=""Id"" type=""string""/><element name=""Name"" type=""string""/><element name=""Email"" type=""string""/></sequence></complexType></element>
      <element name=""UpdateUserResponse""><complexType><sequence><element name=""Status"" type=""string""/></sequence></complexType></element>
    </schema>
  </wsdl:types>
  <wsdl:message name=""GetUserRequest""><part name=""parameters"" element=""tns:GetUserRequest""/></wsdl:message>
  <wsdl:message name=""GetUserResponse""><part name=""parameters"" element=""tns:GetUserResponse""/></wsdl:message>
  <wsdl:message name=""UpdateUserRequest""><part name=""parameters"" element=""tns:UpdateUserRequest""/></wsdl:message>
  <wsdl:message name=""UpdateUserResponse""><part name=""parameters"" element=""tns:UpdateUserResponse""/></wsdl:message>
  <wsdl:portType name=""BillingPortType"">
    <operation name=""GetUser"">
      <input message=""tns:GetUserRequest""/>
      <output message=""tns:GetUserResponse""/>
    </operation>
    <operation name=""UpdateUser"">
      <input message=""tns:UpdateUserRequest""/>
      <output message=""tns:UpdateUserResponse""/>
    </operation>
  </wsdl:portType>
  <wsdl:binding name=""BillingBinding"" type=""tns:BillingPortType"">
    <soap:binding style=""document"" transport=""http://schemas.xmlsoap.org/soap/http""/>
    <operation name=""GetUser""><soap:operation soapAction=""getUser""/><input><soap:body use=""literal""/></input><output><soap:body use=""literal""/></output></operation>
    <operation name=""UpdateUser""><soap:operation soapAction=""updateUser""/><input><soap:body use=""literal""/></input><output><soap:body use=""literal""/></output></operation>
  </wsdl:binding>
  <wsdl:service name=""BillingService"">
    <port name=""BillingPort"" binding=""tns:BillingBinding""><soap:address location=""http://example.com/billing""/></port>
  </wsdl:service>
</wsdl:definitions>";

    private const string SampleWsdlCustomer = @"<wsdl:definitions xmlns:wsdl=""http://schemas.xmlsoap.org/wsdl/"" xmlns:soap=""http://schemas.xmlsoap.org/wsdl/soap/"" xmlns:tns=""http://example.com/customer"" targetNamespace=""http://example.com/customer"">
  <wsdl:types>
    <schema xmlns=""http://www.w3.org/2001/XMLSchema"">
      <element name=""GetProfileRequest""><complexType><sequence><element name=""CustomerId"" type=""string""/></sequence></complexType></element>
      <element name=""GetProfileResponse""><complexType><sequence><element name=""Name"" type=""string""/><element name=""Email"" type=""string""/><element name=""Tier"" type=""string""/></sequence></complexType></element>
      <element name=""SubmitTicketRequest""><complexType><sequence><element name=""Subject"" type=""string""/><element name=""Description"" type=""string""/><element name=""Priority"" type=""string""/></sequence></complexType></element>
      <element name=""SubmitTicketResponse""><complexType><sequence><element name=""TicketId"" type=""string""/><element name=""Status"" type=""string""/></sequence></complexType></element>
    </schema>
  </wsdl:types>
  <wsdl:message name=""GetProfileRequest""><part name=""parameters"" element=""tns:GetProfileRequest""/></wsdl:message>
  <wsdl:message name=""GetProfileResponse""><part name=""parameters"" element=""tns:GetProfileResponse""/></wsdl:message>
  <wsdl:message name=""SubmitTicketRequest""><part name=""parameters"" element=""tns:SubmitTicketRequest""/></wsdl:message>
  <wsdl:message name=""SubmitTicketResponse""><part name=""parameters"" element=""tns:SubmitTicketResponse""/></wsdl:message>
  <wsdl:portType name=""CustomerPortType"">
    <operation name=""GetProfile""><input message=""tns:GetProfileRequest""/><output message=""tns:GetProfileResponse""/></operation>
    <operation name=""SubmitTicket""><input message=""tns:SubmitTicketRequest""/><output message=""tns:SubmitTicketResponse""/></operation>
  </wsdl:portType>
  <wsdl:binding name=""CustomerBinding"" type=""tns:CustomerPortType"">
    <soap:binding style=""document"" transport=""http://schemas.xmlsoap.org/soap/http""/>
    <operation name=""GetProfile""><soap:operation soapAction=""getProfile""/><input><soap:body use=""literal""/></input><output><soap:body use=""literal""/></output></operation>
    <operation name=""SubmitTicket""><soap:operation soapAction=""submitTicket""/><input><soap:body use=""literal""/></input><output><soap:body use=""literal""/></output></operation>
  </wsdl:binding>
  <wsdl:service name=""CustomerService"">
    <port name=""CustomerPort"" binding=""tns:CustomerBinding""><soap:address location=""http://example.com/customer""/></port>
  </wsdl:service>
</wsdl:definitions>";

    private const string SampleWsdlOrders = @"<wsdl:definitions xmlns:wsdl=""http://schemas.xmlsoap.org/wsdl/"" xmlns:soap=""http://schemas.xmlsoap.org/wsdl/soap/"" xmlns:tns=""http://example.com/orders"" targetNamespace=""http://example.com/orders"">
  <wsdl:types>
    <schema xmlns=""http://www.w3.org/2001/XMLSchema"">
      <element name=""CreateOrderRequest""><complexType><sequence><element name=""ItemCode"" type=""string""/><element name=""Quantity"" type=""int""/><element name=""CustomerId"" type=""string""/></sequence></complexType></element>
      <element name=""CreateOrderResponse""><complexType><sequence><element name=""OrderId"" type=""string""/><element name=""Status"" type=""string""/></sequence></complexType></element>
    </schema>
  </wsdl:types>
  <wsdl:message name=""CreateOrderRequest""><part name=""parameters"" element=""tns:CreateOrderRequest""/></wsdl:message>
  <wsdl:message name=""CreateOrderResponse""><part name=""parameters"" element=""tns:CreateOrderResponse""/></wsdl:message>
  <wsdl:portType name=""OrderPortType"">
    <operation name=""CreateOrder""><input message=""tns:CreateOrderRequest""/><output message=""tns:CreateOrderResponse""/></operation>
  </wsdl:portType>
  <wsdl:binding name=""OrderBinding"" type=""tns:OrderPortType"">
    <soap:binding style=""document"" transport=""http://schemas.xmlsoap.org/soap/http""/>
    <operation name=""CreateOrder""><soap:operation soapAction=""createOrder""/><input><soap:body use=""literal""/></input><output><soap:body use=""literal""/></output></operation>
  </wsdl:binding>
  <wsdl:service name=""OrderService"">
    <port name=""OrderPort"" binding=""tns:OrderBinding""><soap:address location=""http://example.com/orders""/></port>
  </wsdl:service>
</wsdl:definitions>";

    private static (List<WsdlSyncRecord> Records, List<WsdlVersionEntry> Versions, List<WsdlTemplate> Templates) GetSeedData()
    {
        var records = new List<WsdlSyncRecord>
        {
            new() { Id = "wsdl-1", AppId = "s1", AppName = "LegacyBilling", SourceType = "url", SourceUrl = "https://soap.billing.com/BillingService?singlewsdl", UploadedBy = "Suresh Kumar", UploadedAt = "2024-06-15 10:30:00", Status = "synced", VersionCount = 2, WsdlContent = SampleWsdlBasic },
            new() { Id = "wsdl-2", AppId = "s1", AppName = "LegacyBilling", SourceType = "upload", SourceUrl = "billing_v2.wsdl", UploadedBy = "Priya Sharma", UploadedAt = "2024-08-01 14:15:00", Status = "synced", VersionCount = 1, WsdlContent = SampleWsdlBasic },
            new() { Id = "wsdl-3", AppId = "s3", AppName = "CustomerPortal", SourceType = "url", SourceUrl = "https://soap.customer.com/PortalService?wsdl", UploadedBy = "Anita Desai", UploadedAt = "2024-05-20 09:00:00", Status = "synced", VersionCount = 3, WsdlContent = SampleWsdlCustomer },
            new() { Id = "wsdl-4", AppId = "s5", AppName = "PaymentGateway", SourceType = "url", SourceUrl = "https://soap.payment.com/Gateway?wsdl", UploadedBy = "Priya Sharma", UploadedAt = "2024-07-10 11:45:00", Status = "parsing", VersionCount = 1, WsdlContent = SampleWsdlBasic },
            new() { Id = "wsdl-5", AppId = "s6", AppName = "OrderProcessing", SourceType = "upload", SourceUrl = "order_service_2024.wsdl", UploadedBy = "Rahul Patel", UploadedAt = "2024-04-05 16:30:00", Status = "synced", VersionCount = 2, WsdlContent = SampleWsdlOrders },
        };

        var versions = new List<WsdlVersionEntry>
        {
            new() { Id = "wv-1", SyncRecordId = "wsdl-1", VersionNumber = 1, Label = "24.20.1", UploadedBy = "Suresh Kumar", UploadedAt = "2024-06-15 10:30:00", Status = "active", Notes = "Initial WSDL import from billing service" },
            new() { Id = "wv-2", SyncRecordId = "wsdl-1", VersionNumber = 2, Label = "24.30.1", UploadedBy = "Suresh Kumar", UploadedAt = "2024-07-20 08:45:00", Status = "active", Notes = "Added new reporting endpoints" },
            new() { Id = "wv-3", SyncRecordId = "wsdl-2", VersionNumber = 1, Label = "24.30.2", UploadedBy = "Priya Sharma", UploadedAt = "2024-08-01 14:15:00", Status = "active", Notes = "Uploaded from local billing_v2.wsdl" },
            new() { Id = "wv-4", SyncRecordId = "wsdl-3", VersionNumber = 1, Label = "24.20.1", UploadedBy = "Anita Desai", UploadedAt = "2024-05-20 09:00:00", Status = "archived", Notes = "Original WSDL" },
            new() { Id = "wv-5", SyncRecordId = "wsdl-3", VersionNumber = 2, Label = "24.20.2", UploadedBy = "Anita Desai", UploadedAt = "2024-06-10 10:30:00", Status = "active", Notes = "Updated profile operations" },
            new() { Id = "wv-6", SyncRecordId = "wsdl-3", VersionNumber = 3, Label = "24.30.1", UploadedBy = "Anita Desai", UploadedAt = "2024-07-05 15:00:00", Status = "active", Notes = "Added support ticket APIs" },
            new() { Id = "wv-7", SyncRecordId = "wsdl-4", VersionNumber = 1, Label = "24.30.1", UploadedBy = "Priya Sharma", UploadedAt = "2024-07-10 11:45:00", Status = "active", Notes = "Awaiting parsing completion" },
            new() { Id = "wv-8", SyncRecordId = "wsdl-5", VersionNumber = 1, Label = "24.10.1", UploadedBy = "Rahul Patel", UploadedAt = "2024-04-05 16:30:00", Status = "active", Notes = "Full order service WSDL" },
            new() { Id = "wv-9", SyncRecordId = "wsdl-5", VersionNumber = 2, Label = "24.10.2", UploadedBy = "Rahul Patel", UploadedAt = "2024-04-20 12:00:00", Status = "active", Notes = "Updated schema for new order types" },
        };

        var templates = new List<WsdlTemplate>
        {
            new()
            {
                Id = "tpl-1", Name = "Standard SOAP Envelope", Description = "Basic SOAP envelope with header and body",
                Content = @"<soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"">
  <soap:Header>
    <Authentication>
      <Username>{{username}}</Username>
      <Password>{{password}}</Password>
    </Authentication>
  </soap:Header>
  <soap:Body>
    <{{operation}} xmlns=""{{namespace}}"">
      <Request>
        <Id>{{request_id}}</Id>
      </Request>
    </{{operation}}>
  </soap:Body>
</soap:Envelope>",
                Variables = ["username", "password", "operation", "namespace", "request_id"],
                CreatedBy = "System", CreatedAt = "2024-01-15", UpdatedAt = "2024-01-15", UsageCount = 24
            },
            new()
            {
                Id = "tpl-2", Name = "Billing Invoice Request", Description = "Extends Standard SOAP Envelope for billing invoice operations",
                ExtendsTemplateId = "tpl-1", ExtendsTemplateName = "Standard SOAP Envelope",
                Content = @"<soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"">
  <soap:Header>
    <Authentication>
      <Username>{{username}}</Username>
      <Password>{{password}}</Password>
    </Authentication>
  </soap:Header>
  <soap:Body>
    <{{operation}} xmlns=""http://billing.example.com/"">
      <InvoiceRequest>
        <InvoiceId>{{invoice_id}}</InvoiceId>
        <CustomerId>{{customer_id}}</CustomerId>
        <Amount>{{amount}}</Amount>
        <Currency>{{currency}}</Currency>
      </InvoiceRequest>
    </{{operation}}>
  </soap:Body>
</soap:Envelope>",
                Variables = ["username", "password", "operation", "invoice_id", "customer_id", "amount", "currency"],
                CreatedBy = "Suresh Kumar", CreatedAt = "2024-02-10", UpdatedAt = "2024-03-05", UsageCount = 15
            },
            new()
            {
                Id = "tpl-3", Name = "Order Processing Template", Description = "Extends Standard SOAP Envelope for order management",
                ExtendsTemplateId = "tpl-1", ExtendsTemplateName = "Standard SOAP Envelope",
                Content = @"<soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"">
  <soap:Header>
    <Authentication>
      <Username>{{username}}</Username>
      <Password>{{password}}</Password>
    </Authentication>
  </soap:Header>
  <soap:Body>
    <{{operation}} xmlns=""http://orders.example.com/"">
      <OrderRequest>
        <OrderId>{{order_id}}</OrderId>
        <CustomerId>{{customer_id}}</CustomerId>
        <ItemCode>{{item_code}}</ItemCode>
        <Quantity>{{quantity}}</Quantity>
      </OrderRequest>
    </{{operation}}>
  </soap:Body>
</soap:Envelope>",
                Variables = ["username", "password", "operation", "order_id", "customer_id", "item_code", "quantity"],
                CreatedBy = "Rahul Patel", CreatedAt = "2024-03-10", UpdatedAt = "2024-04-01", UsageCount = 9
            },
        };

        return (records, versions, templates);
    }
}
