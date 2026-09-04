#!/bin/bash

# Define variables for cleaner code
TOKEN_ENDPOINT="http://localhost:7051/connect/token"
SOAP_ENDPOINT="http://localhost:7051/DocumentService.asmx"

echo "=== 1. Fetching OAuth Token ==="
# Fetch token and extract access_token string
TOKEN_RESPONSE=$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -d "grant_type=client_credentials" \
  -d "client_id=client_app_id_99" \
  -d "client_secret=secret_key_888")

echo "Response: $TOKEN_RESPONSE"

# Extract access_token value using grep/sed
ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

echo -e "\n=== 2. Invoking SOAP Endpoint with Bearer Token ==="
curl -i -X POST "$SOAP_ENDPOINT" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'SOAPAction: "http://servicehub.org/document/soap/IDocumentSoapService/GetDocument"' \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:doc="http://servicehub.org/document/soap">
        <soapenv:Header/>
        <soapenv:Body>
           <doc:GetDocument>
              <doc:request xmlns:types="http://servicehub.org/document/types">
                 <types:DocumentId>DOC-1001</types:DocumentId>
              </doc:request>
           </doc:GetDocument>
        </soapenv:Body>
     </soapenv:Envelope>'

echo -e "\n=== Execution Completed ==="