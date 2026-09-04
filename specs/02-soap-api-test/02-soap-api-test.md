# 02. SOAP API Test

## Purpose

The SOAP API Test feature provides enterprise operational management and visual execution tooling for headless SOAP-based applications (APIs without a native UI). It allows users to group, run, and visually inspect multiple SOAP request/response pairs in real time, while organizing underlying application catalogs, request file repositories, and WSDL synchronization workflows.

## Primary routes

- `/soap/applications`
- `/soap/request-files`
- `/soap/wsdl-sync`
- `/soap/templates`
- `/soap/execute-history`
- `/soap/test-cases` — dedicated per application and per request file
- `/soap/rules` — execution rule management

## Core business outcomes

- **Headless API Operational Visibility:** Provides a dedicated user interface to interact with, trigger, and inspect headless SOAP web services that lack standard frontend interfaces.
- **Ad-Hoc Execution Group Testing:** Enables business analysts and testers to group and execute multiple SOAP request files simultaneously in a single execution package to validate multi-step SOAP operations.
- **Visual Response Inspection & Manual Validation:** Delivers immediate, readable side-by-side displays of request payloads and raw/formatted responses for fast visual verification.
- **Catalog & Artifact Management:** Maintains application definitions, links WSDL schemas, and manages reusable request file repositories across backend environments.
- **Test Cases:** Dedicated test case definitions scoped per application and per request file, enabling structured validation of SOAP responses.
- **Execution Rules:** Custom and global evaluation rules for automated pass/fail determination on SOAP responses.
- **Rule Application:** Test cases support attaching new custom rules or linking common global rules for automated evaluation without manual inspection.

> **Note on Feature Separation:**
> - **Execution Groups (This Feature Area):** Used for manual/ad-hoc batch execution, direct response viewing, and quick visual verification of SOAP endpoints.
> - **Test Suite & Test Case Management (Separate Feature Area):** Handles automated validation rules, assertions, assertions-based pass/fail logic, and saved automated execution packages attached to request files.

## Current implementation anchors

- `Features/OrbitHub.SoapApplications/Pages/`
- `Features/OrbitHub.SoapApplications/Services/`
- `Infrastructure/OrbitHub.Data/SoapManagement/` (SoapDbContext, repositories)
- `Infrastructure/OrbitHub.Data/WsdlManagement/` (WsdlDbContext, repositories)

## Workflow summary

This feature bridges UI-less backend SOAP services with business users by combining application management, WSDL artifact syncing, ad-hoc Execution Group batch runs, and rich XML/JSON response viewing interfaces.