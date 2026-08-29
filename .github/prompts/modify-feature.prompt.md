---
description: "Safely modify feature code within a strict, focused scope"
argument-hint: "Specify target (#file or #folder) and describe the change..."
agent: "agent"
---

# TASK
${input}

# REPOSITORY CONTEXT
This is a **Service Hub Enterprise** Blazor app.
- **Solution:** `OrbitHub.slnx`
- **Web Host:** `WebApp/OrbitHub.Web/`
- **Feature Projects:** Located under `Features/` (e.g., `Features/OrbitHub.Dashboard/`, `Features/OrbitHub.Settings/`, etc.)
- Each feature project contains `Components/`, `Pages/`, `DependencyInjection.cs`, and `_Imports.razor`.

# STRICT EXECUTION SCOPE
- Limit all code edits strictly to the files or areas specified in the task input above.
- Retain all untouched existing logic, comments, and structure.
- If no target file is mentioned in the input, edit only the currently active editor file.
- When adding pages or components to a feature, place them in the feature's own `Pages/` or `Components/` folder respectively.
- When adding NuGet dependencies, update the specific feature's `.csproj` file (not the web host project).