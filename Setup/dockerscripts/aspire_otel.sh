docker run --rm -p 18888:18888 -p 4318:4318 -d --name aspire-dashboard \
    -e ASPIRE_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS=true \
    mcr.microsoft.com/dotnet/aspire-dashboard:latest