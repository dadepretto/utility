initial_password=${1-P@55w0rd}
container_name=${2-sqledge}

docker run \
    --detach \
    --name $container_name \
    --env ACCEPT_EULA=Y \
    --env MSSQL_SA_PASSWORD=$initial_password \
    --volume $HOME/Containers/mssql/staging:/var/opt/mssql/staging \
    --volume $HOME/Containers/mssql/data:/var/opt/mssql/data \
    --volume $HOME/Containers/mssql/log:/var/opt/mssql/log \
    --volume $HOME/Containers/mssql/secrets:/var/opt/mssql/secrets \
    --publish 1433:1433 \
    --restart always \
    mcr.microsoft.com/mssql/server:2019-latest