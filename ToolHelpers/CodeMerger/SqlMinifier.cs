using System.Text;
using System.Text.RegularExpressions;

namespace CodeMerger;

/// <summary>
/// Minifies SQL scripts by removing comments and collapsing whitespace.
/// Supported comment forms are '--' line comments and '/ * ... * /' block
/// comments (with T-SQL style nesting). The contents of string literals
/// ('...'), quoted identifiers ("..."), bracketed identifiers ([...]) and
/// backticked identifiers (`...`) are always preserved verbatim.
/// </summary>
public class SqlMinifier
{
    // Spaces are dropped entirely next to this punctuation (e.g. "a , b"
    // becomes "a,b"); everywhere else whitespace collapses to a single space.
    private const string DropSpaceAfter = ",;(";
    private const string DropSpaceBefore = ",;)=";

    /// <summary>
    /// Minifies every *.sql file found under <paramref name="folderPath"/>
    /// (recursively) and writes each result to <paramref name="mergedOutputFile"/>.
    /// </summary>
    public async Task MinifyFolderAsync(string folderPath, string mergedOutputFile)
    {
        string fullFolderPath = Path.GetFullPath(folderPath);
        if (!Directory.Exists(fullFolderPath))
        {
            throw new DirectoryNotFoundException($"Directory '{fullFolderPath}' does not exist.");
        }

        string[] sqlFiles = [.. Directory.GetFiles(fullFolderPath, "*.sql", SearchOption.AllDirectories)
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}") &&
                        !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}"))];

        if (sqlFiles.Length == 0)
        {
            throw new InvalidOperationException("No .sql files found in the specified directory or its subdirectories.");
        }

        string fullOutputPath = Path.GetFullPath(mergedOutputFile);

        Directory.CreateDirectory(Path.GetDirectoryName(fullOutputPath)!);
        // Ensure the output file is empty before appending to it
        await File.WriteAllTextAsync(mergedOutputFile, string.Empty);

        foreach (string sqlFile in sqlFiles)
        {
            string source = await File.ReadAllTextAsync(sqlFile);
            await File.AppendAllTextAsync(mergedOutputFile, Minify(source));
        }
    }

    /// <summary>
    /// Minifies a single SQL script string: comments are removed and every
    /// run of whitespace outside literals collapses to a single space.
    /// </summary>
    public string Minify(string sql)
    {
        var result = new StringBuilder(sql.Length);
        bool pendingWhitespace = false;
        int i = 0;
        int length = sql.Length;

        while (i < length)
        {
            char c = sql[i];

            // '--' line comment (never recognized inside literals below).
            if (c == '-' && i + 1 < length && sql[i + 1] == '-')
            {
                MarkSeparator(result, ref pendingWhitespace);
                i += 2;
                while (i < length && sql[i] != '\n' && sql[i] != '\r')
                {
                    i++;
                }
                continue;
            }

            // Block comment; nesting is supported the same way T-SQL does it.
            if (c == '/' && i + 1 < length && sql[i + 1] == '*')
            {
                MarkSeparator(result, ref pendingWhitespace);
                i += 2;
                int depth = 1;
                while (i < length && depth > 0)
                {
                    if (sql[i] == '/' && i + 1 < length && sql[i + 1] == '*')
                    {
                        depth++;
                        i += 2;
                    }
                    else if (sql[i] == '*' && i + 1 < length && sql[i + 1] == '/')
                    {
                        depth--;
                        i += 2;
                    }
                    else
                    {
                        i++;
                    }
                }
                continue;
            }

            // Any whitespace outside of literals.
            if (char.IsWhiteSpace(c))
            {
                MarkSeparator(result, ref pendingWhitespace);
                i++;
                continue;
            }

            // Quoted strings / identifiers are copied verbatim.
            if (c == '\'' || c == '"' || c == '`' || c == '[')
            {
                AppendSpaceIfNeeded(result, c, ref pendingWhitespace);
                i = CopyQuoted(sql, i, result);
                continue;
            }

            AppendSpaceIfNeeded(result, c, ref pendingWhitespace);
            result.Append(c);
            i++;
        }
        result.AppendLine();

        return result.ToString();
    }

    private static void MarkSeparator(StringBuilder result, ref bool pendingWhitespace)
    {
        if (result.Length > 0)
        {
            pendingWhitespace = true;
        }
    }

    private static void AppendSpaceIfNeeded(StringBuilder result, char next, ref bool pendingWhitespace)
    {
        if (pendingWhitespace && result.Length > 0)
        {
            char previous = result[result.Length - 1];
            if (!DropSpaceAfter.Contains(previous) && !DropSpaceBefore.Contains(next))
            {
                result.Append(' ');
            }
        }

        pendingWhitespace = false;
    }

    private static int CopyQuoted(string sql, int start, StringBuilder result)
    {
        char opening = sql[start];
        char closing = opening == '[' ? ']' : opening;

        result.Append(opening);
        int i = start + 1;
        int length = sql.Length;

        while (i < length)
        {
            char c = sql[i];
            result.Append(c);

            if (c == closing)
            {
                // Doubled quotes are escapes ('It''s', "a""b", `a``b`) except
                // for bracket identifiers, where ']]' is literal content.
                if (closing != ']' && i + 1 < length && sql[i + 1] == closing)
                {
                    result.Append(closing);
                    i += 2;
                    continue;
                }

                return i + 1;
            }

            i++;
        }

        return i; // Unterminated literal: everything up to the end was copied.
    }
}
