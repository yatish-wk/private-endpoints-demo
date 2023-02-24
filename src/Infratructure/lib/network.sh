function disable_public_access_cosmos() {
    # Disable public access
    echo "Disabling public access to Cosmos DB account '$cosmosAccount'" 
    az cosmosdb update --name $cosmosAccount --resource-group $resourceGroup --enable-public-network false --enable-virtual-network true 
    echo "Public access to Cosmos DB account '$cosmosAccount' has been disabled"
}

function disable_public_access_sql() {
    local location=$1
    local sqlServer="${sqlServer}-${location}"

    # Disable public access 
    echo "Disabling public access to sql server '$sqlServer'" 
    az sql server update --name $sqlServer --resource-group $resourceGroup --enable-public-network false
    echo "Public access to sql server '$sqlServer' has been disabled"
}

function disable_public_access_storage() {
    # Disable public access 
    echo "Disabling public access to storage '$storageAccount'" 
    az storage account update --name $storageAccount --resource-group $resourceGroup  --public-network-access Disabled
    echo "Public access to storage'$storageAccount' has been disabled"
}

function disable_public_access_bus() {
    # TBD - could not find documentation
}