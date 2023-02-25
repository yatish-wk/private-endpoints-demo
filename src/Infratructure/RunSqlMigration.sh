#!/bin/bash

# fail script when any command fails
set -e

source ./lib/vars.sh

sqlServerEast="${sqlServer}-${locEast}"
sqlServerWest="${sqlServer}-${locWest}"

#find primary server in failover group
isPrimary=$(az sql failover-group show \
                    --name $sqlFailoverGroup \
                    --resource-group $resourceGroup \
                    --server $sqlServerEast \
                    --query replicationRole \
                    --output tsv)

if [ "$isPrimary" == "Primary" ]; then
    primaryServer=$sqlServerEast
else
    isPrimary=$(az sql failover-group show \
                    --name $sqlFailoverGroup \
                    --resource-group $resourceGroup \
                    --server $sqlServerWest \
                    --query replicationRole \
                    --output tsv)
    if [ "$isPrimary" == "Primary" ]; then
        primaryServer=$sqlServerWest
    fi
fi

if [ -z "$primaryServer" ]; then
    echo "no primary server found"
    exit 1
fi

agentIp=$(curl ipinfo.io/ip)
connString="Server=tcp:$primaryServer.database.windows.net,1433;Initial Catalog=$sqlDb;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPass;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

#add firewall rule to enable agent ip
az sql server update --name $primaryServer --resource-group $resourceGroup --enable-public-network true
az sql server firewall-rule create -g $resourceGroup -s $primaryServer -n agentrule --start-ip-address $agentIp --end-ip-address $agentIp

#run migration
./efbundle.exe --connection "$connString"

#remove firewall rule
az sql server firewall-rule delete -g $resourceGroup -s $primaryServer -n agentrule 
az sql server update --name $primaryServer --resource-group $resourceGroup --enable-public-network false
