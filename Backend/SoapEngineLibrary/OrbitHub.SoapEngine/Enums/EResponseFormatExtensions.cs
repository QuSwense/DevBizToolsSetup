namespace ServiceHub.SoapEngine.Core.Enums;

public static class EResponseFormatExtensions
{
    /// <summary>
    /// Converts the enum value to its corresponding database string representation.
    /// </summary>
    public static string ToDbString(this EResponseFormat format) => format switch
    {
        EResponseFormat.XML => "XML",
        EResponseFormat.JSON => "JSON",
        EResponseFormat.PDF => "PDF",
        EResponseFormat.BINARY => "BINARY",
        _ => throw new ArgumentOutOfRangeException(nameof(format), format, null)
    };
}