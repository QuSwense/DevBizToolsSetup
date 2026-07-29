namespace ServiceHubEnterprise.SoapApplications.Services;

public class SoapApiEntry
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
}

public record SoapApp(string Id, string Name, string BaseUrl, string Description, string Status, string UpdatedBy, string CreatedDate, int ApisCount, string AuthType, string AuthUsername, string AuthPassword, string AuthExtra, SoapApiEntry[] Apis);

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
            new("s1", "LegacyBilling", "https://soap.billing.com/BillingService", "Enterprise billing service", "enabled", "Suresh Kumar", "2023-08-12", 3, "basic", "billing_user", "", "", [new SoapApiEntry { Name = "SubmitInvoice", Description = "Submit billing invoices" }, new SoapApiEntry { Name = "GetInvoiceStatus", Description = "Check invoice status" }, new SoapApiEntry { Name = "GenerateReport", Description = "Generate billing reports" }]),
            new("s2", "ShippingSOAP", "https://soap.shipping.com/ShipService", "Global shipping and tracking", "disabled", "Priya Sharma", "2023-09-01", 2, "basic", "shipping_admin", "", "", [new SoapApiEntry { Name = "TrackShipment", Description = "Track package location" }, new SoapApiEntry { Name = "CreateLabel", Description = "Generate shipping labels" }]),
            new("s3", "CustomerPortal", "https://soap.customer.com/PortalService", "Customer self-service portal", "enabled", "Anita Desai", "2023-07-05", 5, "basic", "portal_api", "", "", [new SoapApiEntry { Name = "GetProfile", Description = "Fetch customer profile" }, new SoapApiEntry { Name = "UpdateProfile", Description = "Update customer details" }, new SoapApiEntry { Name = "GetOrders", Description = "List customer orders" }, new SoapApiEntry { Name = "SubmitTicket", Description = "Submit support ticket" }, new SoapApiEntry { Name = "GetTicketStatus", Description = "Check ticket status" }]),
            new("s4", "InventorySync", "https://soap.inventory.com/SyncService", "Real-time inventory sync", "disabled", "Vikram Singh", "2024-01-15", 1, "api-key", "sync_user", "sk-sync-abc123", "", [new SoapApiEntry { Name = "SyncInventory", Description = "Synchronize inventory data" }]),
            new("s5", "PaymentGateway", "https://soap.payment.com/Gateway", "Payment processing gateway", "enabled", "Priya Sharma", "2023-11-20", 4, "bearer", "", "eyJhbGciOiJIUzI1NiJ9.eyJ...", "", [new SoapApiEntry { Name = "ProcessPayment", Description = "Process customer payment" }, new SoapApiEntry { Name = "RefundTransaction", Description = "Issue refund" }, new SoapApiEntry { Name = "GetTransactionLog", Description = "Retrieve transaction log" }, new SoapApiEntry { Name = "ValidateCard", Description = "Validate credit card" }]),
            new("s6", "OrderProcessing", "https://soap.orders.com/OrderService", "Order management system", "enabled", "Rahul Patel", "2024-03-10", 6, "ntlm", "ORDERS\\svc_order", "p@ssw0rd", "ORDERS", [new SoapApiEntry { Name = "CreateOrder", Description = "Create new order" }, new SoapApiEntry { Name = "CancelOrder", Description = "Cancel existing order" }, new SoapApiEntry { Name = "GetOrderDetails", Description = "Get order details" }, new SoapApiEntry { Name = "UpdateOrderStatus", Description = "Update order status" }, new SoapApiEntry { Name = "ListOrders", Description = "List all orders" }, new SoapApiEntry { Name = "GetOrderHistory", Description = "Get order history" }]),
            new("s7", "NotificationHub", "https://soap.notify.com/NotifyService", "Centralized notification service", "enabled", "Suresh Kumar", "2024-02-28", 3, "none", "", "", "", [new SoapApiEntry { Name = "SendEmail", Description = "Send email notification" }, new SoapApiEntry { Name = "SendSms", Description = "Send SMS notification" }, new SoapApiEntry { Name = "GetDeliveryStatus", Description = "Check delivery status" }]),
            new("s8", "ReportingEngine", "https://soap.report.com/ReportService", "Business reporting engine", "disabled", "Anita Desai", "2023-10-12", 2, "basic", "report_user", "", "", [new SoapApiEntry { Name = "GenerateReport", Description = "Generate business report" }, new SoapApiEntry { Name = "ExportReport", Description = "Export report as file" }])
        ];
    }
}
