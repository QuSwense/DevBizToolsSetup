# 05. Test Suite

## Purpose

The Test Suite feature provides the execution and validation model for API testing, quality checks, and outcome tracking across the application. It acts as the **multi-protocol orchestrator**, aggregating test cases from both SOAP and REST testing workflows into unified, automated execution packages.

## Primary routes

- `/test/cases`
- `/test/suites`
- `/test/executions`
- `/test/criteria`
- `/test/rules`

## Core business outcomes

- Define reusable test cases for both SOAP and REST protocols.
- Organize cases into suites that span multiple applications and protocols.
- **Multi-Protocol Aggregation:** Test Suites aggregate test cases across different applications (SOAP and REST) into a single orchestrated execution.
- **Automated Rule Evaluation:** Attach custom rules or link global rules to test cases for automated pass/fail determination.
- Run and review historical test executions with cross-application reporting.
- Validate outcomes against success criteria.
- **Orchestration:** Test Suites serve as the orchestrator for multi-application, multi-protocol automated test execution, enabling end-to-end workflow validation.

## Current implementation anchors

- `Features/OrbitHub.TestSuite/Pages/`
- `Features/OrbitHub.TestSuite/DependencyInjection.cs`
