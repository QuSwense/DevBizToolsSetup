#!/bin/bash

# Configuration
ENDPOINT="http://localhost:7050/CustomerService.asmx"
USERNAME="admin_user"
PASSWORD="SuperSecretPassword123!"

echo "=================================================="
echo "    TESTING BASIC AUTH SOAP SERVICE (PORT 7050)   "
echo "=================================================="

# Check if server is running on port 7050
echo "---> Checking connection to $ENDPOINT..."
if ! curl -i --connect-timeout 3 "$ENDPOINT?wsdl" > /dev/null 2>&1; then
    echo " [ERROR] Cannot connect to $ENDPOINT!"
    echo " Make sure MockCustomerSoapService is running on port 7050 (dotnet run)."
    exit 1
fi
echo " [OK] Server is reachable."

echo -e "\n---> 1. Testing Unauthenticated Request (Expect 401 Unauthorized)..."
curl -i -X POST "$ENDPOINT" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H 'SOAPAction: "http://servicehub.org/customer/soap/ICustomerSoapService/GetCustomerProfile"' \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cust="http://servicehub.org/customer/soap">
        <soapenv:Header/>
        <soapenv:Body>
           <cust:GetCustomerProfile>
              <cust:request xmlns:types="http://servicehub.org/customer/types">
                 <types:CustomerId>101</types:CustomerId>
                 <types:RequestorId>TEST_RUNNER</types:RequestorId>
                 <types:IncludeTransactionHistory>true</types:IncludeTransactionHistory>
              </cust:request>
           </cust:GetCustomerProfile>
        </soapenv:Body>
     </soapenv:Envelope>'

echo -e "\n\n---> 2. Testing Authenticated Request (Expect 200 OK)..."
curl -i -X POST "$ENDPOINT" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H 'SOAPAction: "http://servicehub.org/customer/soap/ICustomerSoapService/GetCustomerProfile"' \
  -u "$USERNAME:$PASSWORD" \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cust="http://servicehub.org/customer/soap">
        <soapenv:Header/>
        <soapenv:Body>
           <cust:GetCustomerProfile>
              <cust:request xmlns:types="http://servicehub.org/customer/types">
                 <types:CustomerId>101</types:CustomerId>
                 <types:RequestorId>TEST_RUNNER</types:RequestorId>
                 <types:IncludeTransactionHistory>true</types:IncludeTransactionHistory>
              </cust:request>
           </cust:GetCustomerProfile>
        </soapenv:Body>
     </soapenv:Envelope>'

echo -e "\n\n=================================================="
echo "               TEST EXECUTION FINISHED            "
echo "=================================================="