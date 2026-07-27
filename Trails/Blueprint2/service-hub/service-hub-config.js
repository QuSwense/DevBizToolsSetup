/* ============================================================
   SERVICE HUB V8 — Configuration & Data
   Separated from UI logic, following DataGrid philosophy.
   ============================================================ */

// --- REST Applications ---
const SH_REST_APPS = [
    {
        id: "1", name: "PaymentService",
        baseUrl: "https://api.payments.com/v1",
        swaggerUrl: "https://api.payments.com/swagger.json",
        status: "enabled",
        lastUpdatedBy: "Priya Sharma",
        createdDate: "2024-01-15",
        apisCount: 4,
        summary: "Handles payment processing and refunds",
        apis: [
            { id: "a1", path: "/payments", verb: "POST", summary: "Create payment" },
            { id: "a2", path: "/payments/{id}", verb: "GET", summary: "Get payment status" },
            { id: "a3", path: "/refunds", verb: "POST", summary: "Refund payment" },
            { id: "a4", path: "/methods", verb: "GET", summary: "List methods" }
        ]
    },
    {
        id: "2", name: "UserManagement",
        baseUrl: "https://api.users.internal/v2",
        status: "enabled",
        lastUpdatedBy: "Rahul Patel",
        createdDate: "2024-02-20",
        apisCount: 3,
        summary: "User CRUD and auth",
        apis: [
            { id: "b1", path: "/users", verb: "GET", summary: "List users" },
            { id: "b2", path: "/users", verb: "POST", summary: "Create user" },
            { id: "b3", path: "/users/{id}", verb: "DELETE", summary: "Delete user" }
        ]
    },
    {
        id: "3", name: "InventoryAPI",
        baseUrl: "https://inventory.acme.com/api",
        status: "disabled",
        lastUpdatedBy: "Anita Desai",
        createdDate: "2023-11-10",
        apisCount: 5,
        summary: "Stock and warehouse",
        apis: [
            { id: "c1", path: "/stock", verb: "GET", summary: "Get stock" },
            { id: "c2", path: "/stock", verb: "PUT", summary: "Update stock" }
        ]
    },
    {
        id: "4", name: "OrderService",
        baseUrl: "https://orders.acme.com/v3",
        status: "enabled",
        lastUpdatedBy: "Vikram Singh",
        createdDate: "2024-03-05",
        apisCount: 2,
        summary: "",
        apis: [
            { id: "d1", path: "/orders", verb: "POST", summary: "Create order" },
            { id: "d2", path: "/orders/{id}", verb: "GET", summary: "Get order" }
        ]
    }
];

// --- SOAP Applications ---
const SH_SOAP_APPS = [
    {
        id: "s1", name: "LegacyBilling",
        baseUrl: "https://soap.billing.com/BillingService",
        status: "enabled",
        lastUpdatedBy: "Suresh Kumar",
        createdDate: "2023-08-12",
        apisCount: 3,
        summary: "SOAP billing operations",
        apis: [
            { id: "s-a1", operation: "CreateInvoice", path: "", verb: "POST", summary: "Create invoice" },
            { id: "s-a2", operation: "GetInvoice", path: "", verb: "POST", summary: "Get invoice details" },
            { id: "s-a3", operation: "CancelInvoice", path: "", verb: "POST", summary: "Cancel invoice" }
        ]
    },
    {
        id: "s2", name: "ShippingSOAP",
        baseUrl: "https://soap.shipping.com/ShipService",
        status: "disabled",
        lastUpdatedBy: "Priya Sharma",
        createdDate: "2023-09-01",
        apisCount: 2,
        summary: "",
        apis: [
            { id: "s-b1", operation: "TrackShipment", path: "", verb: "POST", summary: "Track" },
            { id: "s-b2", operation: "CreateLabel", path: "", verb: "POST", summary: "Create label" }
        ]
    }
];

// --- Request Files ---
const SH_REQUEST_FILES = [
    {
        id: "rf1", fileName: "payment_create_001.json",
        appId: "1", appName: "PaymentService",
        apiPath: "/payments", verb: "POST",
        description: "Valid payment with card 4111",
        type: "json", source: "REST",
        domainUrl: "https://api.payments.com",
        appDesc: "Handles payment processing and refunds",
        apiSummary: "Create payment",
        createdDate: "2024-04-01"
    },
    {
        id: "rf2", fileName: "user_list_filter.xml",
        appId: "2", appName: "UserManagement",
        apiPath: "/users", verb: "GET",
        description: "List active users filtered by role admin",
        type: "xml", source: "REST",
        domainUrl: "https://api.users.internal",
        appDesc: "User CRUD and auth",
        apiSummary: "List users",
        createdDate: "2024-04-02"
    },
    {
        id: "rf3", fileName: "invoice_create.xml",
        appId: "s1", appName: "LegacyBilling",
        apiPath: "CreateInvoice", verb: "POST",
        description: "SOAP envelope for invoice creation with tax",
        type: "xml", source: "SOAP",
        domainUrl: "https://soap.billing.com",
        appDesc: "SOAP billing operations",
        apiSummary: "Create invoice",
        createdDate: "2024-03-20"
    },
    {
        id: "rf4", fileName: "stock_update_003.json",
        appId: "3", appName: "InventoryAPI",
        apiPath: "/stock", verb: "PUT",
        description: "Update stock for SKU-889",
        type: "json", source: "REST",
        domainUrl: "https://inventory.acme.com",
        appDesc: "Stock and warehouse",
        apiSummary: "Update stock",
        createdDate: "2024-04-03"
    }
];

// --- Sample activity log ---
const SH_ACTIVITY_LOG = [
    { user: "Priya Sharma", action: "created application PaymentService", time: "2 hours ago" },
    { user: "Rahul Patel", action: "executed Test Suite Smoke Suite and 12 files passed", time: "2 hours ago" },
    { user: "Anita Desai", action: "disabled application InventoryAPI", time: "5 hours ago" },
    { user: "Vikram Singh", action: "added 3 new APIs to OrderService", time: "yesterday" },
    { user: "Suresh Kumar", action: "imported WSDL for LegacyBilling and 3 operations synced", time: "yesterday" },
    { user: "Priya Sharma", action: "created template Payment Success Template", time: "1 day ago" },
    { user: "System", action: "detected Billing SOAP service down", time: "2 hours ago" }
];

// --- Test suite summary ---
const SH_TEST_SUITES = [
    { name: "Smoke Suite", cases: 6, files: 18 },
    { name: "Regression Core", cases: 12, files: 42 },
    { name: "Payment Full", cases: 4, files: 15 },
    { name: "SOAP Billing", cases: 3, files: 9 }
];

// --- Health checks ---
const SH_HEALTH = [
    { name: "Payment Gateway", status: "ok" },
    { name: "User API", status: "ok" },
    { name: "Billing SOAP", status: "down" },
    { name: "Inventory", status: "ok" },
    { name: "Shipping SOAP", status: "down" }
];
