namespace DocIntercept.Settings;

/// <summary>
/// Toggles that drive the post-scaffold entity formatter. Mirrors (and extends)
/// the old format-entities.py behavior. Every rule is independently configurable
/// from the <c>scaffoldFormat</c> section of DocIntercept.settings.json or via
/// CLI overrides on the <c>format</c> command.
/// </summary>
public sealed class ScaffoldFormatOptions
{
    /// <summary>
    /// Split the scaffolder's single-line
    /// <c>[Column(...)] public Prop { get; set; }</c> members into a separate
    /// attribute line followed by a property line.
    /// </summary>
    public bool SplitColumnAttributes { get; set; } = true;

    /// <summary>
    /// Convert the scaffolder's block-scoped <c>namespace X { ... }</c> into a
    /// file-scoped <c>namespace X;</c> (dedenting the body by one level).
    /// </summary>
    public bool FileScopedNamespaces { get; set; } = true;

    /// <summary>
    /// Collapse the alignment padding the scaffolder inserts around split
    /// members (2+ spaces, spaces before commas / inside parens).
    /// Only applies when <see cref="SplitColumnAttributes"/> is on.
    /// </summary>
    public bool SqueezeAlignmentPadding { get; set; } = true;

    /// <summary>
    /// Insert an empty line between consecutive class members so every property
    /// (doc comment + attributes + declaration) reads as its own block.
    /// </summary>
    public bool BlankLineBetweenMembers { get; set; } = true;

    /// <summary>Glob used to find files to format inside the target directory.</summary>
    public string SearchPattern { get; set; } = "*.cs";

    /// <summary>Recurse into subdirectories of the target directory.</summary>
    public bool RecurseSubdirectories { get; set; } = true;
}
