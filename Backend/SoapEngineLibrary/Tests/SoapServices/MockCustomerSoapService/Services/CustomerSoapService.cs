namespace MockCustomerSoapService.Services;

using MockCustomerSoapService.Models;

public class CustomerSoapService : ICustomerSoapService
{
    public CustomerProfileResponse GetCustomerProfile(CustomerProfileRequest request)
    {
        return new CustomerProfileResponse
        {
            CustomerId = request.CustomerId,
            FullName = "Johnathan Doe",
            Email = "jdoe@example.com",
            AccountType = EAccountType.Enterprise,
            VerificationStatus = EVerificationStatus.FullyVerified,
            PrimaryAddress = new AddressDto
            {
                Street = "100 Innovation Way",
                City = "San Francisco",
                State = "CA",
                ZipCode = "94105",
                Country = "USA"
            },
            SecondaryAddresses =
            [
                new AddressDto
                {
                    Street = "500 Market St",
                    City = "San Francisco",
                    State = "CA",
                    ZipCode = "94104",
                    Country = "USA"
                }
            ],
            PreferredContactChannels = ["Email", "SMS"],
            MemberSince = DateTime.UtcNow.AddYears(-2)
        };
    }

    public CreateCustomerResponse CreateCustomer(CreateCustomerRequest request)
    {
        int id = Random.Shared.Next(1000, 9999);
        return new CreateCustomerResponse
        {
            GeneratedCustomerId = id,
            AccountNumber = $"ACC-{id}-US",
            Status = EVerificationStatus.PendingKYC,
            CreatedAt = DateTime.UtcNow
        };
    }

    public TransactionResponse ProcessFinancialTransaction(TransactionRequest request)
    {
        return new TransactionResponse
        {
            TransactionId = $"TXN-{Guid.NewGuid():N}"[..12].ToUpper(),
            Status = "SUCCESS",
            Currency = request.Currency,
            ProcessedAmount = request.Amount,
            RemainingBalance = 45200.75m,
            ProcessedAt = DateTime.UtcNow
        };
    }

    public SupportTicketResponse SubmitSupportTicket(SupportTicketRequest request)
    {
        return new SupportTicketResponse
        {
            TicketNumber = $"TKT-{Random.Shared.Next(10000, 99999)}",
            AssignedQueue = "L2_TECHNICAL_SUPPORT",
            EscalationPriority = request.Priority,
            Status = "Open",
            EstimatedResolutionDate = DateTime.UtcNow.AddDays(2)
        };
    }
}