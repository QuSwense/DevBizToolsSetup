namespace ServiceHub.SoapEngine.Core.Exceptions;

/// <summary>
/// Thrown when the remote endpoint returns an explicit &lt;soap:Fault&gt; XML payload.
/// </summary>
public class SoapFaultException : SoapException
{
    public string FaultCode { get; }
    public string FaultString { get; }
    public string? FaultActor { get; }
    public string? DetailXml { get; }

    public SoapFaultException(string faultCode, string faultString, string? faultActor = null, string? detailXml = null)
        : base($"SOAP Fault Received [{faultCode}]: {faultString}")
    {
        FaultCode = faultCode;
        FaultString = faultString;
        FaultActor = faultActor;
        DetailXml = detailXml;
    }

    public SoapFaultException(string faultCode, string faultString, Exception innerException)
        : base($"SOAP Fault Received [{faultCode}]: {faultString}", innerException)
    {
        FaultCode = faultCode;
        FaultString = faultString;
    }
}