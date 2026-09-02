namespace MockCustomerSoapService.Services;

using System.ServiceModel;
using MockCustomerSoapService.Models;

[ServiceContract(Namespace = "http://servicehub.org/customer/soap")]
public interface ICustomerSoapService
{
    [OperationContract]
    CustomerProfileResponse GetCustomerProfile(CustomerProfileRequest request);

    [OperationContract]
    CreateCustomerResponse CreateCustomer(CreateCustomerRequest request);

    [OperationContract]
    TransactionResponse ProcessFinancialTransaction(TransactionRequest request);

    [OperationContract]
    SupportTicketResponse SubmitSupportTicket(SupportTicketRequest request);
}