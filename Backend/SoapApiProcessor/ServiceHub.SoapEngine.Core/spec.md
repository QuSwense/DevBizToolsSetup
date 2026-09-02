# Updated Business and Technical Specification Summary: ServiceHub.SoapEngine.Core

> **Scope**: This library manages the complete lifecycle of SOAP-based web services, including application registration, WSDL parsing, versioning, request/response file storage with compression and delta history, and batch execution. It does **not** include test suite management, user permissions, or user administration – those are handled by separate libraries.

---

## Core Responsibilities

- **Catalog & Lifecycle Management** – Register SOAP applications with metadata, health‑check endpoints, and atomic updates. WSDL inspection (from URL or file) automatically discovers operations, SOAP actions, input/output element names, and embedded XSD schemas.
- **Automated Versioning** – Uses `YY.QQ.NN` format (year.quarter.sequence) for applications, WSDL syncs, request files, and response files. Automatically handles quarter resets.
- **Authentication** – Securely stores credentials (Basic, API Key, OAuth2, NTLM) with AES‑256‑GCM encryption.
- **Data Optimization** – GZip compression for XML payloads; backward delta‑diff chain (up to 5 versions) before consolidating to a full snapshot.
- **Batch Execution** – Create execution groups, run them sequentially, capture per‑item latency, HTTP status, and store compressed response files with versioning.
- **Data Retrieval for UI** – Exposes query methods to list applications, operations, request files, execution groups, runs, etc., with filtering and pagination support.

---

## Technical Overview

- **Framework**: .NET 10 (`net10.0`)
- **ORM**: LINQ to DB (SQL Server)
- **Dependencies**: `System.Security.Cryptography.AesGcm`, `DiffPlex` (diffs), built‑in `HttpClient`
- **DI Registration**: Single extension method `AddServiceHubSoapEngine` registers all services, repositories, and HTTP clients.

---

## Key Modules & Services

| Module | Service / Class | Purpose |
|--------|----------------|---------|
| **WSDL Parsing** | `WsdlParser` | Parses WSDL 1.1/2.0, extracts operations, SOAP actions, namespaces, and inline XSD schemas (`wsdl:types`). `XmlSchemaExtractor` (to be implemented) will provide advanced schema extraction if needed. |
| **Application Management** | `SoapApplicationService` | Orchestrates creation, update, WSDL sync, credential configuration, and operation upsert. Uses `SoapVersionGeneratorService` for versioning. |
| **Execution Orchestrator** | `SoapExecutionGroupRunner` | Runs batch execution sets, handles item status, stores responses, and updates run statuses. |
| **HTTP Transport** | `SoapClientService` | Performs SOAP POST calls with authentication (Basic, OAuth2, API Key, NTLM), decompresses payloads, and detects SOAP faults. |
| **Encryption** | `SoapEncryptionService` | AES‑256‑GCM encryption/decryption of credential objects (serialized to JSON). |
| **Compression & Delta** | `SoapFileCompressor`, `SoapFileDeltaPatcher` | GZip compression/decompression; backward diff generation and application using `DiffPlex`. |
| **Versioning** | `SoapVersionGeneratorService` | Generates `YY.QQ.NN` strings based on current UTC quarter. |

---

## Database Tables (Core)

All tables are defined in the provided SQL script. The library interacts with:

- **Catalog**: `SoapApplications`, `SoapAppAuthentication`, `SoapOperations`, `SoapOperationSchemas`, `SoapNamespaces`
- **WSDL Sync**: `SoapWsdlSync`, `SoapWsdlHistory`
- **Request Files**: `SoapRequestFiles`, `SoapRequestFileHistory`
- **Execution**: `SoapExecutionGroups`, `SoapExecutionGroupItems`, `SoapExecutionRuns`, `SoapExecutionItemRuns`
- **Response Files**: `SoapResponseFiles`, `SoapResponseEmbeddings`, `SoapResponseFileHistory`

> **Note**: Test suites, permissions, and user management tables are **not** used by this library.

---

## Public API (Input DTOs & Service Methods)

### 1. WSDL Inspection
- **Input**: `InspectWsdlInput` (WsdlUrl or WsdlFileStream)  
- **Method**: `SoapApplicationService.InspectWsdlOperationsAsync`  
- **Returns**: List of `ParsedWsdlOperationDto` (includes `TargetNamespace`).

### 2. Full Application Creation
- **Input**: `CreateFullApplicationInput` (metadata, auth type & credentials, operations list)  
- **Method**: `SoapApplicationService.CreateFullApplicationAsync`  
- **Behavior**: Registers app, configures auth, creates operations (manual or from WSDL).

### 3. Application Update
- **Input**: `UpdateFullApplicationInput` (metadata, optional auth update, operations)  
- **Method**: `SoapApplicationService.UpdateFullApplicationAsync`  
- **Behavior**: Updates metadata, optionally auth, and upserts operations.

### 4. WSDL Synchronization
- **Input**: `SyncWsdlInput` (AppId, WsdlUrl or file stream, comment)  
- **Method**: `SoapApplicationService.SyncWsdlAsync`  
- **Behavior**: Parses WSDL, stores new version, creates/updates operations and schemas.

### 5. Request File Upload
- **Input**: `UploadRequestFileInput` (OperationId, FileName, FileStream, CreatedBy)  
- **Method**: `SoapApplicationService.UploadRequestFileStreamAsync`  
- **Behavior**: Compresses, stores, and creates history chain (diff or full snapshot based on diff count).

### 6. Execution Group Management
- **Input**: `CreateExecutionGroupInput` (AppId, GroupName, Items)  
- **Repository Method**: `SoapExecutionRepository.CreateGroupAsync`  
- **Trigger Execution**: `SoapExecutionGroupRunner.RunGroupAsync(groupId, executedBy)`  
- **Behavior**: Runs items sequentially, records each item run, stores response files.

### 7. Data Retrieval (for UI)
The library provides repository methods (or service facades) to query:

- Applications (by ID, name, active status, etc.)
- Operations (by application, active status)
- Request files (by operation, by ID, with history)
- Execution groups (by application, by ID)
- Execution runs (by group, by status, by date)
- Response files (by execution item run)

These methods support optional filtering (e.g., `IsActive`, date ranges, user‑related fields) and pagination via `Skip`/`Take`.

---

## Authentication Models

- **AuthCredentialsBase** (abstract) – defines `AuthenticationType` and `CredentialsPayload`.
- Concrete types: `BasicAuthCredentials`, `ApiKeyAuthCredentials`, `OAuth2Credentials`, `NtlmAuthCredentials`.
- The `GenericAuthCredentialsWrapper` is **removed**; authentication configuration now uses the concrete types directly via the `Credentials` property in `ConfigureAuthInput` and `CreateFullApplicationInput`.

---

## Dependency Injection Setup

```csharp
services.AddServiceHubSoapEngine(
    connectionString: "...",
    encryptionBase64Key: "<32‑byte‑base64‑key>"
);
```

Registers all services, repositories, `HttpClient` instances, and the `SoapEngineDataContext`.

---

## Summary of Out‑of‑Scope Features

- Test Suites, Test Cases, Validation Rules – handled by a separate testing library.
- User management (CRUD) – separate identity/administration library.
- Permission enforcement – UI layer is responsible for access control.

---