# OrbitHub C# & .NET Guidelines

### C# Language Standards

* **File-Scoped Namespaces:** Always use `namespace Company.Feature;` (.NET 6+).
* **Primary Constructors:** Use for dependency injection in classes/records. Avoid manual backing-field assignment.
* **Property Modifiers:** Use `required` and `init` for non-nullable, immutable properties on DTOs and models.
* **Collection Expressions:** Use `[...]` and spread syntax `..` instead of `new List<T>()`, `Array.Empty<T>()`, or `.ToList()`.
* **Raw String Literals:** Use `"""..."""` for JSON, SQL, XML, or multi-line strings.
* **`field` Keyword:** Use C# 14 `field` for property validation/normalization; avoid explicit backing fields.

### Naming & Style

* **PascalCase:** Types, interfaces (`I`), enums, public/protected members, public constants.
* **camelCase:** Parameters, local variables.
* **`_camelCase`:** Private fields and private constants.
* **Async Suffix:** Append `Async` to all methods returning `Task` or `ValueTask`.
* **Formatting:** Max 120 chars/line. Document public APIs with `/// <summary>`.

### Architecture & Data Access

* **Blazor UI:** Access data strictly via domain services/mediators; never call `DbContext` or raw SQL directly.
* **Data Access:** Keep EF Core/Linq2db contexts in `Infrastructure/OrbitHub.Data`. Feature projects expose their own interfaces.
* **Stored Procedures & Views:** Query generated `usp_*` methods for procedures and strongly typed `v_*` views for read-only reporting/grids.
* **Cancellation:** Propagate `CancellationToken` through all async repository, DB, and HTTP calls.

## Performance

* Use generics as much as possible than usin `object` or any RTTI.