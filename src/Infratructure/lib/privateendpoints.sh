function create_endpoint_cosmos() {
    local location=$1
    local vnetName="${vnetName}-${location}"
    local subnetName="privateendpoints"
    local privateEndpointName="cosmos-${privateEndpointName}-${location}"
    
    # Check if private endpoint already exists
    if az network private-endpoint show --name $privateEndpointName --resource-group $resourceGroup  >/dev/null 2>&1; then
        echo "Private endpoint '$privateEndpointName' for resource'$cosmosAccount' already exists. Skipping private endpoint creation...."
    else
        # Get resourceId
        local resourceId=$(az cosmosdb show --name $cosmosAccount --resource-group $resourceGroup --query id --out tsv)

        echo "Creating private endpoint '$privateEndpointName'..."
        echo "executing - az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetName --location $location --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id Sql"
        MSYS_NO_PATHCONV=1 az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetName --location $location --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id Sql
        
        #echo "Approving the private endpoint.."
        #az cosmosdb private-endpoint-connection approve --account-name $cosmosAccount --name $privateEndpointName --resource-group $resourceGroup --description "Approved"
        echo "Private endpoint '$privateEndpointName' has been created."
    fi

    # local zoneName="privatelink.documents.azure.com"
    create_private_dns_zone $cosmosZoneName $location
    link_private_zone_to_vnet $cosmosZoneName $location
    create_private_dns_zone_group $cosmosZoneName $privateEndpointName $location
}

function create_endpoint_sql() {
    local location=$1
    local vnetLocation=$2
    local sqlServer="${sqlServer}-${location}"
    local vnetName="${vnetName}-${vnetLocation}"
    local subnetName="privateendpoints"
    local privateEndpointName="sql--${location}-${privateEndpointName}-for-vnet-${vnetLocation}"
    
    # Check if private endpoint already exists
    if az network private-endpoint show --name $privateEndpointName --resource-group $resourceGroup  >/dev/null 2>&1; then
        echo "Private endpoint '$privateEndpointName' for resource'$sqlServer' already exists. Skipping private endpoint creation...."
    else
        # Get resourceId
        local resourceId=$(az sql server show \
                            --resource-group $resourceGroup \
                            --name $sqlServer \
                            --query id \
                            --output tsv)

        echo "Creating private endpoint '$privateEndpointName'..."
        echo "executing - az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $vnetLocation --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id sqlServer"
        MSYS_NO_PATHCONV=1 az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $vnetLocation --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id sqlServer
        
        #echo "Approving the private endpoint.."
        #az network private-endpoint-connection approve --name $privateEndpointName --resource-group $resourceGroup --resource-name $sqlServer --type Microsoft.Sql/servers --description "Approved"
        echo "Private endpoint '$privateEndpointName' has been created."
    fi

    # local zoneName="privatelink.database.windows.net"
    create_private_dns_zone $sqlZoneName $vnetLocation
    link_private_zone_to_vnet $sqlZoneName $vnetLocation
    create_private_dns_zone_group $sqlZoneName $privateEndpointName $vnetLocation
}

function create_endpoint_storage() {
    local location=$1
    local vnetName="${vnetName}-${location}"
    local subnetName="privateendpoints"
    local privateEndpointName="storage-blob-${privateEndpointName}-${location}"
    
    # Check if private endpoint already exists
    if az network private-endpoint show --name $privateEndpointName --resource-group $resourceGroup  >/dev/null 2>&1; then
        echo "Private endpoint '$privateEndpointName' for resource'$storageAccount' already exists. Skipping private endpoint creation...."
    else
        # Get resourceId
        local resourceId=$(az storage account show \
                            --resource-group $resourceGroup \
                            --name $storageAccount \
                            --query id \
                            --output tsv)

        echo "Creating private endpoint '$privateEndpointName'..."
        echo "executing - az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $location --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id blob"
        MSYS_NO_PATHCONV=1 az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $location --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id blob
        
        #echo "Approving the private endpoint.."
        #az storage account private-endpoint-connection approve --name $privateEndpointName --resource-group $resourceGroup --account-name $storageAccount --description "Approved"
        echo "Private endpoint '$privateEndpointName' has been created."
    fi

    # local zoneName="privatelink.blob.core.windows.net"
    create_private_dns_zone $storageZoneName $location
    link_private_zone_to_vnet $storageZoneName $location
    create_private_dns_zone_group $storageZoneName $privateEndpointName $location
}

function create_endpoint_bus() {
    local location=$1
    local serviceBusNamespace="${serviceBusNamespace}-${location}"
    local vnetName="${vnetName}-${location}"
    local subnetName="privateendpoints"
    local privateEndpointName="servicebus-${privateEndpointName}-${location}"
    
    # Check if private endpoint already exists
    if az network private-endpoint show --name $privateEndpointName --resource-group $resourceGroup  >/dev/null 2>&1; then
        echo "Private endpoint '$privateEndpointName' for resource'$serviceBusNamespace' already exists. Skipping private endpoint creation...."
    else
        # Get resourceId
        local resourceId=$(az servicebus namespace show  \
                            --resource-group $resourceGroup \
                            --name $serviceBusNamespace \
                            --query id \
                            --output tsv)

        echo "Creating private endpoint '$privateEndpointName'..."
        echo "executing - az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $location --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id namespace"
        MSYS_NO_PATHCONV=1 az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --location $location --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id $resourceId --connection-name $privateEndpointName --group-id namespace
        
        #echo "Approving the private endpoint.."
        #az servicebus namespace private-endpoint-connection approve --name $privateEndpointName --resource-group $resourceGroup --namespace-name $serviceBusNamespace
        echo "Private endpoint '$privateEndpointName' has been created."
    fi

    # local zoneName="privatelink.servicebus.windows.net"
    create_private_dns_zone $servicebusZoneName $location
    link_private_zone_to_vnet $servicebusZoneName $location
    create_private_dns_zone_group $servicebusZoneName $privateEndpointName $location
}
