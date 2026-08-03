using ServiceHubEnterprise.Common;

namespace ServiceHubEnterprise.Tests.Common;

public class SharedUtilitiesTests
{
    [Fact]
    public void IsValidCSharpIdentifier_ReturnsTrue_ForValidMethodNames()
    {
        Assert.True(NamingConventionValidator.IsValidCSharpIdentifier("GetOrder"));
        Assert.True(NamingConventionValidator.IsValidCSharpIdentifier("_value1"));
    }

    [Fact]
    public void IsValidCSharpIdentifier_ReturnsFalse_ForKeywordsAndInvalidNames()
    {
        Assert.False(NamingConventionValidator.IsValidCSharpIdentifier("class"));
        Assert.False(NamingConventionValidator.IsValidCSharpIdentifier("1stValue"));
        Assert.False(NamingConventionValidator.IsValidCSharpIdentifier("Get-Order"));
    }

    [Fact]
    public void IsValidAppName_ReturnsFalse_ForInvalidCharacters()
    {
        Assert.True(NamingConventionValidator.IsValidAppName("Invoice Service"));
        Assert.True(NamingConventionValidator.IsValidAppName("Müller"));
        Assert.False(NamingConventionValidator.IsValidAppName("Invoice-Service"));
        Assert.False(NamingConventionValidator.IsValidAppName("Invoice@Service"));
    }

    [Fact]
    public void IsValidWsdlPath_ReturnsFalse_ForUrls()
    {
        Assert.True(NamingConventionValidator.IsValidWsdlPath("/service?wsdl"));
        Assert.True(NamingConventionValidator.IsValidWsdlPath("?wsdl"));
        Assert.False(NamingConventionValidator.IsValidWsdlPath("https://example.com/service?wsdl"));
        Assert.False(NamingConventionValidator.IsValidWsdlPath("http://example.com/service"));
    }

    [Fact]
    public void EncodeField_QuotesAndEscapesEmbeddedQuotes()
    {
        const string expected = "\"Hello\"";
        const string input = "Hello";
        Assert.Equal(expected, CsvTextHelper.EncodeField(input));

        const string expectedQuoted = "\"A \"\"quoted\"\" value\"";
        const string inputQuoted = "A \"\"quoted\"\" value";
        Assert.Equal(expectedQuoted, CsvTextHelper.EncodeField(inputQuoted));
    }

    [Fact]
    public void GetLanguageFromExtension_UsesCustomFallbackForViewer()
    {
        Assert.Equal("plaintext", FileFormatHelper.GetLanguageFromExtension("archive.bin", "plaintext"));
        Assert.Equal("xml", FileFormatHelper.GetLanguageFromExtension("archive.bin"));
    }
}
