namespace MockCustomerSoapService.Models;

using System.Runtime.Serialization;

#region Namespace 1: Customer Domain Types
[DataContract(Namespace = "http://servicehub.org/customer/types")]
public enum EAccountType
{
    [EnumMember] Standard = 1,
    [EnumMember] Premium = 2,
    [EnumMember] Enterprise = 3,
    [EnumMember] VIP = 4
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public enum EVerificationStatus
{
    [EnumMember] Unverified,
    [EnumMember] PendingKYC,
    [EnumMember] FullyVerified,
    [EnumMember] Suspended
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public class AddressDto
{
    [DataMember(IsRequired = true)] public required string Street { get; set; }
    [DataMember(IsRequired = true)] public required string City { get; set; }
    [DataMember(IsRequired = true)] public required string State { get; set; }
    [DataMember(IsRequired = true)] public required string ZipCode { get; set; }
    [DataMember(IsRequired = true)] public required string Country { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public class CustomerProfileRequest
{
    [DataMember(IsRequired = true)] public required int CustomerId { get; set; }
    [DataMember(IsRequired = true)] public required string RequestorId { get; set; }
    [DataMember] public bool IncludeTransactionHistory { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public class CustomerProfileResponse
{
    [DataMember(IsRequired = true)] public required int CustomerId { get; set; }
    [DataMember(IsRequired = true)] public required string FullName { get; set; }
    [DataMember(IsRequired = true)] public required string Email { get; set; }
    [DataMember(IsRequired = true)] public required EAccountType AccountType { get; set; }
    [DataMember(IsRequired = true)] public required EVerificationStatus VerificationStatus { get; set; }
    [DataMember(IsRequired = true)] public required AddressDto PrimaryAddress { get; set; }
    [DataMember] public List<AddressDto> SecondaryAddresses { get; set; } = [];
    [DataMember] public List<string> PreferredContactChannels { get; set; } = [];
    [DataMember] public DateTime MemberSince { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public class CreateCustomerRequest
{
    [DataMember(IsRequired = true)] public required string FirstName { get; set; }
    [DataMember(IsRequired = true)] public required string LastName { get; set; }
    [DataMember(IsRequired = true)] public required string Email { get; set; }
    [DataMember(IsRequired = true)] public required EAccountType AccountType { get; set; }
    [DataMember(IsRequired = true)] public required AddressDto PrimaryAddress { get; set; }
    [DataMember] public decimal InitialDepositAmount { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/customer/types")]
public class CreateCustomerResponse
{
    [DataMember(IsRequired = true)] public required int GeneratedCustomerId { get; set; }
    [DataMember(IsRequired = true)] public required string AccountNumber { get; set; }
    [DataMember(IsRequired = true)] public required EVerificationStatus Status { get; set; }
    [DataMember] public DateTime CreatedAt { get; set; }
}
#endregion

#region Namespace 2: Financial Domain Types
[DataContract(Namespace = "http://servicehub.org/financial/types")]
public enum ECurrencyCode
{
    [EnumMember] USD,
    [EnumMember] EUR,
    [EnumMember] GBP,
    [EnumMember] JPY,
    [EnumMember] CAD
}

[DataContract(Namespace = "http://servicehub.org/financial/types")]
public enum ETransactionType
{
    [EnumMember] Transfer,
    [EnumMember] Deposit,
    [EnumMember] Withdrawal,
    [EnumMember] Payment
}

[DataContract(Namespace = "http://servicehub.org/financial/types")]
public class TransactionRequest
{
    [DataMember(IsRequired = true)] public required string SourceAccountNumber { get; set; }
    [DataMember(IsRequired = true)] public required string DestinationAccountNumber { get; set; }
    [DataMember(IsRequired = true)] public required decimal Amount { get; set; }
    [DataMember(IsRequired = true)] public required ECurrencyCode Currency { get; set; }
    [DataMember(IsRequired = true)] public required ETransactionType TransactionType { get; set; }
    [DataMember] public string? ReferenceNote { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/financial/types")]
public class TransactionResponse
{
    [DataMember(IsRequired = true)] public required string TransactionId { get; set; }
    [DataMember(IsRequired = true)] public required string Status { get; set; }
    [DataMember(IsRequired = true)] public required ECurrencyCode Currency { get; set; }
    [DataMember] public decimal ProcessedAmount { get; set; }
    [DataMember] public decimal RemainingBalance { get; set; }
    [DataMember] public DateTime ProcessedAt { get; set; }
}
#endregion

#region Namespace 3: Support Domain Types
[DataContract(Namespace = "http://servicehub.org/support/types")]
public enum ETicketPriority
{
    [EnumMember] Low = 1,
    [EnumMember] Medium = 2,
    [EnumMember] High = 3,
    [EnumMember] Critical = 4
}

[DataContract(Namespace = "http://servicehub.org/support/types")]
public enum ETicketCategory
{
    [EnumMember] Billing,
    [EnumMember] Technical,
    [EnumMember] AccountAccess,
    [EnumMember] SecurityAlert
}

[DataContract(Namespace = "http://servicehub.org/support/types")]
public class SupportTicketRequest
{
    [DataMember(IsRequired = true)] public required int CustomerId { get; set; }
    [DataMember(IsRequired = true)] public required string Subject { get; set; }
    [DataMember(IsRequired = true)] public required ETicketCategory Category { get; set; }
    [DataMember(IsRequired = true)] public required ETicketPriority Priority { get; set; }
    [DataMember(IsRequired = true)] public required string DetailedDescription { get; set; }
}

[DataContract(Namespace = "http://servicehub.org/support/types")]
public class SupportTicketResponse
{
    [DataMember(IsRequired = true)] public required string TicketNumber { get; set; }
    [DataMember(IsRequired = true)] public required string AssignedQueue { get; set; }
    [DataMember(IsRequired = true)] public required ETicketPriority EscalationPriority { get; set; }
    [DataMember(IsRequired = true)] public required string Status { get; set; }
    [DataMember] public DateTime EstimatedResolutionDate { get; set; }
}
#endregion