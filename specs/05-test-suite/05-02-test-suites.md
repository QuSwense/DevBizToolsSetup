# 05-02. Test Suites

## Scope

This sub-feature covers grouping multiple test cases into suites for execution and reporting, supporting multi-application, multi-protocol orchestration.

## Responsibilities

- Organize test cases into meaningful execution groups.
- Provide suite-level execution patterns.
- Support broader validation flows beyond one-off case execution.
- **Multi-Protocol Aggregation:** A single Test Suite can include test cases from both SOAP and REST applications.
- **Cross-Application Orchestration:** Test Suites orchestrate test cases across different applications, enabling end-to-end workflow validation.

## Business expectations

Test suites should help users validate a complete scenario or workflow rather than isolated checks in isolation.

## Orchestration Model

### Suite Composition
- A Test Suite contains an ordered collection of test case references.
- Each test case reference identifies:
  - The source application (SOAP or REST)
  - The specific request file
  - The expected execution order or dependency

### Execution Flow
1. The Test Suite iterates through its test cases in defined order.
2. Each test case is executed against its parent application's execution engine (SOAP or REST).
3. Attached rules are evaluated against the response.
4. Results are collected per-test-case and rolled up into a suite-level report.
5. Execution can be configured to stop on first failure or continue through all cases.

### Reporting
- Suite-level summary: total cases, passed, failed, skipped.
- Per-case drill-down: request/response pairs, rule evaluation results.
- Historical execution logs for trend analysis.
