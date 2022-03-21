docker run \
    --detach \
    --name sqledge \
    --env ACCEPT_EULA=Y \
    --env MSSQL_SA_PASSWORD=<YourSqlPasswordHere> \
    --volume /Users/<YourSystemUsername>/docker/sqledge/staging:/var/opt/mssql/staging \
    --volume /Users/<YourSystemUsername>/docker/sqledge/data:/var/opt/mssql/data \
    --volume /Users/<YourSystemUsername>/docker/sqledge/log:/var/opt/mssql/log \
    --volume /Users/<YourSystemUsername>/docker/sqledge/secrets:/var/opt/mssql/secrets \
    --publish 1433:1433 \
    --restart always \
    mcr.microsoft.com/azure-sql-edge