# 05-01. Test Cases

## Scope

This sub-feature covers the definition and management of individual test cases for both SOAP and REST API testing.

## Responsibilities

- Define extraction or validation assertions.
- Provide a reusable set of case definitions for SOAP, REST, or system validation workflows.
- Connect test cases to the request data and execution model.
- **Protocol-Aware:** Test cases are scoped per application and per request file, supporting both SOAP and REST protocols.

## Business expectations

Test cases should be precise, reusable, and directly tied to the data or contract under validation.

## Execution Rules

Test cases support two modes of rule-based evaluation:

### Custom Rules (Per-Case)
- Users can define new custom rules directly on a test case.
- Custom rules are scoped to that specific test case and are not shared.
- Rules can evaluate response status codes, payload content, headers, timing, or schema conformance.

### Global Rules (Shared Library)
- Users can link common global rules from a shared rule library.
- Global rules are defined once and reused across multiple test cases and applications.
- Example global rules: "Status code equals 200", "Response time under 2 seconds", "XML schema matches WSDL".

### Rule Application Flow
1. A test case is created for a specific application and request file.
2. One or more rules are attached — either newly created custom rules or existing global rules.
3. Rules can be combined (AND logic) for comprehensive validation.
4. During execution, each rule is evaluated against the response.
5. Results are reported per-rule (pass/fail) and aggregated into an overall test case verdict.
