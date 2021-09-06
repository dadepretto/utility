docker run \
    --detach \
    --name mssql \
    --env ACCEPT_EULA=Y \
    --env MSSQL_SA_PASSWORD=<YourSqlPasswordHere> \
    --volume /Users/<YourSystemUsername>/docker/mssql/staging:/var/opt/mssql/staging \
    --volume /Users/<YourSystemUsername>/docker/mssql/data:/var/opt/mssql/data \
    --volume /Users/<YourSystemUsername>/docker/mssql/log:/var/opt/mssql/log \
    --volume /Users/<YourSystemUsername>/docker/mssql/secrets:/var/opt/mssql/secrets \
    --publish 1433:1433 \
    mcr.microsoft.com/mssql/server:2019-latest