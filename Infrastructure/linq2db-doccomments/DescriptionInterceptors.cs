// ---------------------------------------------------------------------------------------------------
// linq2db.cli (6.4.0) does NOT expose any CLI flag or linq2db.json key to scaffold
// MS_Description extended properties into XML doc comments. This interceptor fills
// that gap: it reads MS_Description from sys.extended_properties and maps it onto the
// generated CodeModel via ScaffoldInterceptors.PreprocessEntity.
//
// Build (must target net10.0 to match the CLI runtime, and reference the SAME
// linq2db.Scaffold 6.4.0 that linq2db.cli ships with):
//   dotnet build scripts/linq2db-doccomments/DocIntercept.csproj
// Then pass the resulting DLL to each scaffold invocation:
//   --customize "<path>/DocIntercept.dll"
//
// The same assembly also ships a `format` CLI that replaces the old
// format-entities.py post-processing step; both behaviors are configured from
// DocIntercept.settings.json (see Formatting/DocInterceptSettings.cs).
// ---------------------------------------------------------------------------------------------------

using DocIntercept.Settings;
using LinqToDB.CodeModel;
using LinqToDB.DataModel;
using LinqToDB.Scaffold;
using Microsoft.Data.SqlClient;

namespace DocIntercept;

/// <summary>
/// Maps MS SQL Server extended properties (MS_Description) onto generated
/// <c>&lt;summary&gt;</c> doc comments for entity classes and column properties.
/// Enabled/connection string come from the <c>descriptionInterceptors</c> section
/// of DocIntercept.settings.json, overridable with the <c>LINQ2DB_CONNECTION</c>
/// environment variable.
/// </summary>
public sealed class DescriptionInterceptors : ScaffoldInterceptors
{
    private readonly Dictionary<string, string> _tableDescriptions = new();
    private readonly Dictionary<string, string> _columnDescriptions = new();
    private readonly bool _enabled;
    private bool _loaded;

    public DescriptionInterceptors()
    {
        var options = DocInterceptSettings.Load(DocInterceptSettings.DefaultSettingsPath()).DescriptionInterceptors;
        _enabled = options.Enabled;
        _connectionString = options.ConnectionString;
    }

    private readonly string? _connectionString;

    // Priority: LINQ2DB_CONNECTION env var -> DocIntercept.settings.json
    // descriptionInterceptors.connectionString -> development default.
    // Empty/whitespace values are treated as "not configured" so the settings
    // file can ship with a blank connectionString placeholder.
    private string ConnectionString =>
        new[] { Environment.GetEnvironmentVariable("LINQ2DB_CONNECTION"), _connectionString }
            .FirstOrDefault(s => !string.IsNullOrWhiteSpace(s))
        ?? "Data Source=localhost,1433;Initial Catalog=OrbitTool;User ID=sa;Password=root@1234;Encrypt=True;TrustServerCertificate=True;Command Timeout=30";

    private void EnsureLoaded()
    {
        if (!_enabled || _loaded) return;
        _loaded = true;

        using var connection = new SqlConnection(ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = @"
SELECT s.name + '.' + o.name AS obj, o.name AS obj_bare, c.name AS col, ep.value
FROM sys.extended_properties ep
JOIN sys.objects  o ON o.object_id = ep.major_id
JOIN sys.schemas  s ON s.schema_id = o.schema_id
LEFT JOIN sys.columns c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
WHERE ep.name = N'MS_Description' AND o.type IN ('U','V')";

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var obj = reader.GetString(0);
            var bare = reader.GetString(1);
            var col = reader.IsDBNull(2) ? null : reader.GetString(2);
            var value = reader.IsDBNull(3) ? "" : reader.GetString(3);

            if (string.IsNullOrWhiteSpace(value)) continue;

            if (col == null)
            {
                _tableDescriptions[obj] = value;
                _tableDescriptions[bare] = value;
            }
            else
            {
                _columnDescriptions[$"{obj}.{col}"] = value;
                _columnDescriptions[$"{bare}.{col}"] = value;
            }
        }
    }

    public override void PreprocessEntity(ITypeParser typeParser, EntityModel entityModel)
    {
        EnsureLoaded();

        var tableName = entityModel.Metadata.Name?.Name;
        if (tableName != null && _tableDescriptions.TryGetValue(tableName, out var tableSummary))
            entityModel.Class.Summary = tableSummary;

        foreach (var column in entityModel.Columns)
        {
            var columnName = column.Metadata.Name;
            if (tableName != null && columnName != null
                && _columnDescriptions.TryGetValue($"{tableName}.{columnName}", out var columnSummary))
                column.Property.Summary = columnSummary;
        }
    }
}
