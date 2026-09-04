dotnet linq2db scaffold \
  -p SqlServer \
  -c "Data Source=localhost,1433;Initial Catalog=ServiceHubDb;User ID=sa;Password=root@1234;Pooling=False;Connect Timeout=30;Encrypt=False;TrustServerCertificate=True;Authentication=SqlPassword;Command Timeout=30" \
  -o ./Data/Generated \
  -n ServiceHub.SoapEngine.Core.Data.Generated \
  --context-name SoapEngineDataContext \
  --include-tables "SoapApplications,SoapAppAuthentication,SoapWsdlSync,SoapWsdlHistory,SoapOperations,SoapOperationSchemas,SoapNamespaces,SoapRequestFiles,SoapRequestFileHistory,SoapExecutionGroups,SoapExecutionGroupItems,SoapExecutionRuns,SoapExecutionItemRuns,SoapResponseFiles,SoapResponseEmbeddings,SoapResponseFileHistory"