# AGENTS.md

This file gives AI coding agents the project-level context they need when working in this repository.

## Where the authoritative project knowledge lives

- **`.github/copilot-instructions.md`** — the canonical, git-checked-in project memory: architecture & structure, Blazor/CSS/C# standards, the critical solution map, execution & scope rules, the `mock_db` business spec, the SOAP Execute & Test-Cases feature map, and implementation gotchas. Copilot Chat auto-loads this file whenever this workspace is opened.
- **`Features/ServiceHubEnterprise.SoapApplications/docs/redesign-plan.md`** — versioned design/implementation plan for the SOAP UI journey + execute engine + test cases.
- **`Features/ServiceHubEnterprise.SoapApplications/docs/feature-redesign-template.md`** — reusable checklist template for redesigning any feature using the shared UI kit + `ServiceHubGrid<TItem>`.

## Working agreements

1. **Read `.github/copilot-instructions.md` first** before making changes — it defines the coding standards (code-behind `.razor.cs`, CSS variables, naming, DI, `mock_db` rules) and the **Zero Unrequested Edits** scope rule.
2. **Solution map**: solution `ServiceHubEnterprise.slnx`; host `WebApp/ServiceHubEnterprise.Web`; feature projects under `Features/`; shared components under `Components/` (`ServiceHubEnterprise.Grid`, `ServiceHubEnterprise.Ui`).
3. **Mock data** lives in `mock_db/` and is accessed via `MockDbLoader` (`MockDb:Path` config). Persist mutations with `MockDbLoader.SaveJsonAsync`.
4. **Do not alter** `ServiceHubEnterprise.slnx` project references unless explicitly asked.
5. **Before adding NuGet packages**, check the relevant `.csproj` first; ask before introducing new dependencies.
6. **If a task needs changes outside the requested context, stop and ask.**
