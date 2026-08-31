# Dockerfile for custom Azure SQL Edge with sqlcmd installed
# Optimized for ARM64 (Apple Silicon M1/M2/M3/M4/M5)

FROM mcr.microsoft.com/azure-sql-edge:latest

USER root

# Install sqlcmd and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql18 \
        mssql-tools18 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/mssql-tools18/bin:${PATH}"

# Create necessary directories
RUN mkdir -p \
    /var/opt/mssql/data \
    /var/opt/mssql/log \
    /var/opt/mssql/backup \
    /var/opt/mssql/secrets

# Fix permissions using numeric UID
RUN chown -R 10001:10001 /var/opt/mssql

# Convenient shortcut for the backup directory
RUN ln -sf /var/opt/mssql/backup /backup

# Create database initialization script.
# MSSQL_SA_USER, MSSQL_SA_PASSWORD and DATABASE_NAME are
# supplied at container runtime by start.sh.
RUN echo '#!/bin/bash' > /usr/local/bin/init-db.sh && \
    echo 'echo "=== Initializing SQL Server Database ==="' >> /usr/local/bin/init-db.sh && \
    echo 'RETRIES=30' >> /usr/local/bin/init-db.sh && \
    echo 'while true; do' >> /usr/local/bin/init-db.sh && \
    echo '    /opt/mssql-tools18/bin/sqlcmd -S localhost -U "${MSSQL_SA_USER}" -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" > /dev/null 2>&1' >> /usr/local/bin/init-db.sh && \
    echo '    if [ $? -eq 0 ]; then' >> /usr/local/bin/init-db.sh && \
    echo '        echo "SQL Server is ready!"' >> /usr/local/bin/init-db.sh && \
    echo '        break' >> /usr/local/bin/init-db.sh && \
    echo '    fi' >> /usr/local/bin/init-db.sh && \
    echo '    RETRIES=$((RETRIES - 1))' >> /usr/local/bin/init-db.sh && \
    echo '    if [ $RETRIES -eq 0 ]; then' >> /usr/local/bin/init-db.sh && \
    echo '        echo "Error: SQL Server failed to start within the expected time."' >> /usr/local/bin/init-db.sh && \
    echo '        exit 1' >> /usr/local/bin/init-db.sh && \
    echo '    fi' >> /usr/local/bin/init-db.sh && \
    echo '    echo "SQL Server not ready yet... waiting 2 seconds."' >> /usr/local/bin/init-db.sh && \
    echo '    sleep 2' >> /usr/local/bin/init-db.sh && \
    echo 'done' >> /usr/local/bin/init-db.sh && \
    echo '' >> /usr/local/bin/init-db.sh && \
    echo 'if [ -z "${MSSQL_DATABASE_NAME:-}" ]; then' >> /usr/local/bin/init-db.sh && \
    echo '    echo "Error: MSSQL_DATABASE_NAME is not configured."' >> /usr/local/bin/init-db.sh && \
    echo '    exit 1' >> /usr/local/bin/init-db.sh && \
    echo 'fi' >> /usr/local/bin/init-db.sh && \
    echo '' >> /usr/local/bin/init-db.sh && \
    echo 'echo "Creating ${MSSQL_DATABASE_NAME} database if not exists..."' >> /usr/local/bin/init-db.sh && \
    echo '/opt/mssql-tools18/bin/sqlcmd -S localhost -U "${MSSQL_SA_USER}" -P "${MSSQL_SA_PASSWORD}" -C -d master -Q "IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = '\''${MSSQL_DATABASE_NAME}'\'') CREATE DATABASE [${MSSQL_DATABASE_NAME}];"' >> /usr/local/bin/init-db.sh && \
    echo '' >> /usr/local/bin/init-db.sh && \
    echo 'VERIFY=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U "${MSSQL_SA_USER}" -P "${MSSQL_SA_PASSWORD}" -C -d master -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '\''${MSSQL_DATABASE_NAME}'\'';" -h -1 2>/dev/null | tr -d " \t\n\r")' >> /usr/local/bin/init-db.sh && \
    echo 'if [ "${VERIFY}" = "1" ]; then' >> /usr/local/bin/init-db.sh && \
    echo '    echo "Database ${MSSQL_DATABASE_NAME} exists."' >> /usr/local/bin/init-db.sh && \
    echo 'else' >> /usr/local/bin/init-db.sh && \
    echo '    echo "Failed to create database ${MSSQL_DATABASE_NAME}."' >> /usr/local/bin/init-db.sh && \
    echo 'fi' >> /usr/local/bin/init-db.sh && \
    echo 'echo "=== Database initialization complete ==="' >> /usr/local/bin/init-db.sh

# Create entrypoint script
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'echo "=== Starting Custom SQL Server Entrypoint ==="' >> /usr/local/bin/entrypoint.sh && \
    echo '/usr/local/bin/init-db.sh &' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "Starting SQL Server..."' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec /opt/mssql/bin/sqlservr' >> /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/init-db.sh /usr/local/bin/entrypoint.sh

RUN chown 10001:10001 \
    /usr/local/bin/init-db.sh \
    /usr/local/bin/entrypoint.sh

USER 10001

WORKDIR /var/opt/mssql

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "${MSSQL_SA_USER}" \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -Q "SELECT 1" || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
