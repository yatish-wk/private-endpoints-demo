function create_resource_group() {
    local location=$1
    if [ $(az group exists --name $resourceGroup | tr -dc [:alpha:]) == "false" ]
    then
        echo "Creating resource group $resourceGroup"
        az group create --name $resourceGroup --location $location
    else
        echo "Resource group $resourceGroup already exists, skipping.."
    fi
}

function create_dns_resource_group() {
    local location=$1
    local resourceGroup="${dnsResourceGroup}-${location}"
    
    if [ $(az group exists --name $resourceGroup | tr -dc [:alpha:]) == "false" ]
    then
        echo "Creating resource group $resourceGroup"
        az group create --name $resourceGroup --location $location
    else
        echo "Resource group $resourceGroup already exists, skipping.."
    fi
}

function create_appservice_plan() {
    # create app service plan
    local location=$1
    local appSvcPlan="${appSvcPlan}-${location}"

    if [ $(az appservice plan list -g $resourceGroup --query "[?name == '$appSvcPlan'] | length(@)" | tr -dc '0-9') == 0 ]
    then
        echo "Create new app service plan $appSvcPlan"
        az appservice plan create --name $appSvcPlan --resource-group $resourceGroup --location $location --sku P1V2
    else
        echo "App Service plan $appSvcPlan already exists, skipping.."
    fi
}

function create_web_app() {
    # create web app
    local location=$1
    local appSvcPlan="${appSvcPlan}-${location}"
    local webApp="${webApp}-${location}"

    if [ $(az webapp list -g $resourceGroup --query "[?name == '$webApp'] | length(@)" | tr -dc '0-9') == 0 ]
    then
        echo "Create new web app $webApp"
        az webapp create --name $webApp --plan $appSvcPlan -g $resourceGroup --runtime "DOTNET|6.0" --https-only true
    else
        echo "Web app $webApp already exists, skipping.."
    fi
}

function set_webapp_app_setting() {
    local location=$1
    local settingName=$2
    local settingValue=$3
    local webApp="${webApp}-${location}"

    az webapp config appsettings set -g $resourceGroup -n $webApp --settings $settingName="$settingValue"
}

function set_webapp_conn_string() {
    local location=$1
    local connStringType=$2
    local connStringName=$3
    local conStringValue=$4
    local webApp="${webApp}-${location}"

    az webapp config connection-string set --connection-string-type $connStringType \
                    -g $resourceGroup -n $webApp \
                    --settings $connStringName="${conStringValue}"
}


function create_cosmos_account() {
    # create cosmos db
    if [ $(az cosmosdb check-name-exists --name $cosmosAccount | tr -dc [:alpha:]) == "false" ]
    then
        echo "Create new cosmosdb $cosmosAccount"
        az cosmosdb create --name $cosmosAccount  --resource-group $resourceGroup \
            --locations regionName=$locEast failoverPriority=0 isZoneRedundant=False \
            --locations regionName=$locWest failoverPriority=1 isZoneRedundant=False
    else
        echo "cosmos account $cosmosAccount already exists, skipping.."
    fi

     # fetch cosmos url & keys
    out_cosmosEndpointUrl=$(az cosmosdb show --name $cosmosAccount --resource-group $resourceGroup --query "documentEndpoint" -o tsv)
    out_primaryKey=$(az cosmosdb keys list --name $cosmosAccount  --resource-group $resourceGroup --query primaryMasterKey --output tsv)
}

function create_cosmos_db() {
    # create database
    if [ $(az cosmosdb sql database exists --name $cosmosDatabase --account-name $cosmosAccount --resource-group $resourceGroup | tr -dc [:alpha:]) == "false" ]
    then
        echo "Create new database $cosmosDatabase"
        az cosmosdb sql database create --name $cosmosDatabase --account-name $cosmosAccount --resource-group $resourceGroup
    else
        echo "database $cosmosDatabase already exists, skipping.."
    fi
}

function create_container() {
    # create container 
    local store=$1
    if [ $(az cosmosdb sql container exists --name $store --database-name $cosmosDatabase --account-name $cosmosAccount --resource-group $resourceGroup | tr -dc [:alpha:]) == "false" ]
    then
        echo "Create new container $store"

        MSYS_NO_PATHCONV=1 az cosmosdb sql container create --name $store \
                                --partition-key-path "/partitionKey" \
                                --database-name $cosmosDatabase \
                                --account-name $cosmosAccount \
                                --resource-group $resourceGroup
    else
        echo "container $store already exists, skipping.."
    fi
}

function create_sql_server() {
    local location=$1
    local sqlServer="${sqlServer}-${location}"

    exists=$(az sql server show --name $sqlServer --resource-group $resourceGroup --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The Azure SQL Server $sqlServer exists in the resource group."
    else
        echo "Creating The Azure SQL Server $sqlServer"
        az sql server create --name $sqlServer --resource-group $resourceGroup --location "$location" --admin-user $sqlLogin --admin-password $sqlPass
    fi
}

function create_sql_db() {
    local location=$1
    local sqlServer="${sqlServer}-${location}"

    exists=$(az sql db show --server $sqlServer --name $sqlDb --resource-group $resourceGroup --query name --output tsv 2>/dev/null)
    
    if [ -n "$exists" ]; then
        echo "The sql db $sqlDb exists. Skipping..."
    else
        echo "Creating The Azure SQL db $sqlDb"
        az sql db create --resource-group $resourceGroup --server $sqlServer --name $sqlDb
    fi

}

function create_failover_group() {
    local location=$1
    local locationSecondary=$2

    local sqlServerPrimary="${sqlServer}-${location}"
    local sqlServerSecondary="${sqlServer}-${locationSecondary}"

    exists=$(az sql failover-group show --server $sqlServerPrimary --name $sqlFailoverGroup --resource-group $resourceGroup --query name --output tsv 2>/dev/null)
    
    if [ -n "$exists" ]; then
        echo "The sql failover group $sqlFailoverGroup exists. Skipping..."
    else
        echo "Creating The Azure SQLfailover group $sqlFailoverGroup"
        az sql failover-group create --name $sqlFailoverGroup --partner-server $sqlServerSecondary --resource-group $resourceGroup --server $sqlServerPrimary --partner-resource-group $resourceGroup --add-db $sqlDb
    fi

    out_sqlConnectionString="Server=tcp:$sqlFailoverGroup.database.windows.net,1433;Initial Catalog=$sqlDb;Persist Security Info=False;User ID=$sqlLogin;Password=$sqlPass;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

function create_storage_account() {
    local location=$1
    local sku="Standard_GRS"

    exists=$(az storage account show --name $storageAccount --resource-group $resourceGroup --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The Azure Storage Account '$storageAccount' exists. Skipping.."
    else
        echo "The Azure Storage Account '$storageAccount' does not exist in the resource group '$resourceGroup', creating it now..."
        az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku $sku --kind StorageV2 
        az storage account update --name $storageAccount --resource-group $resourceGroup --encryption-services blob
        az storage account update --name $storageAccount --resource-group $resourceGroup --encryption-services file
        echo "The Azure Storage Account '$storageAccount' has been created successfully."
    fi

    out_storageConnectionString=$(az storage account show-connection-string --name $storageAccount --resource-group $resourceGroup --query connectionString --output tsv)
}

function create_service_bus_namespace() {
    local location=$1
    local serviceBusNamespace="${serviceBusNamespace}-${location}"
    local sku="Premium"

    exists=$(az servicebus namespace show --name $serviceBusNamespace --resource-group $resourceGroup --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The Azure Service Bus Namespace '$serviceBusNamespace' exists in the resource group '$resourceGroup'. Skipping..."
    else
        echo "The Azure Service Bus Namespace '$serviceBusNamespace' does not exist in the resource group '$resourceGroup', creating it now..."
        az servicebus namespace create --name $serviceBusNamespace --resource-group $resourceGroup --location $location --sku $sku
        echo "The Azure Service Bus Namespace '$serviceBusNamespace' has been created successfully."
        
        az servicebus queue create --resource-group $resourceGroup --namespace-name $serviceBusNamespace --name $queueName
        echo "Queue'$queueName' has been created successfully."
    fi

    local connString=$(az servicebus namespace authorization-rule keys list --resource-group $resourceGroup --namespace-name ${serviceBusNamespace} --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)
    eval "out_busConnectionString_$location"='$connString'
}

function create_function_app() {
    local location=$1
    local functionApp="${functionApp}-${location}"
    local runtime="dotnet"
    local osType="Windows"
    local functionVersion="4"

    exists=$(az functionapp show --name $functionApp --resource-group $resourceGroup --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The Azure Function App '$functionApp' exists in the resource group '$resourceGroup'. Skipping...."
    else
        echo "The Azure Function App '$functionApp' does not exist in the resource group '$resourceGroup', creating it now..."
        az functionapp create --name $functionApp --resource-group $resourceGroup --consumption-plan-location $location --os-type $osType --runtime $runtime --functions-version $functionVersion --storage-account $storageAccount --disable-app-insights true
        echo "The Azure Function App '$functionApp' has been created successfully."
    fi
}

function create_vnet() {
    local location=$1
    local addressPrefix=$2
    
    local subnet1Address=$3
    local subnet1Name="privateendpoints"
    local subnet2Address=$4
    local subnet2Name="integration"

    local vnetName="${vnetName}-${location}"

    exists=$(az network vnet show --name $vnetName --resource-group $resourceGroup --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The Virtual Network '$vnetName' exists in the resource group '$resourceGroup'. Skipping..."
    else
        echo "The Virtual Network '$vnetName' does not exist in the resource group '$resourceGroup', creating it now..."
        az network vnet create --name $vnetName --resource-group $resourceGroup --location $location --address-prefix $addressPrefix
        echo "The Virtual Network '$vnetName' has been created successfully."
        
        echo "Now creating two subnets... one for private endpoints, other for outbound integration of web apps.."
        az network vnet subnet create --name $subnet1Name --vnet-name $vnetName --address-prefixes $subnet1Address --resource-group $resourceGroup
        az network vnet subnet create --name $subnet2Name --vnet-name $vnetName --address-prefixes $subnet2Address --resource-group $resourceGroup
        echo "done creating subnets!"
    fi
}

function peer_vnets() {
    local peeringName="vnetpeering"
    local vnetNameRemote="${vnetName}-${locWest}"
    local vnetName="${vnetName}-${locEast}"

    exists=$(az network vnet peering show --name $peeringName --resource-group $resourceGroup --vnet-name $vnetName --query name --output tsv 2>/dev/null)

    if [ -n "$exists" ]; then
        echo "The VNet Peering '$peeringName' exists in the resource group '$resourceGroup'. Skipping ..."
    else
        echo "The VNet Peering '$peeringName' does not exist in the resource group '$resourceGroup', creating it now..."
        # peer vnet1 -> vnet2
        az network vnet peering create --name $peeringName --resource-group $resourceGroup --vnet-name $vnetName --remote-vnet $vnetNameRemote --allow-vnet-access --allow-forwarded-traffic
        # peer vnet2 -> vnet1
        az network vnet peering create --name $peeringName --resource-group $resourceGroup --vnet-name $vnetNameRemote --remote-vnet $vnetName --allow-vnet-access --allow-forwarded-traffic
        echo "The VNet Peering '$peeringName' has been created successfully."
    fi
}

function vnet_integration() {
    local location=$1
    local webApp="${webApp}-${location}"
    local vnetName="${vnetName}-${location}"
    local subnetName="integration"

    exists=$(az webapp vnet-integration list -g $resourceGroup -n $webApp --query "[].name" --output tsv)

    if [ -n "$exists" ]; then
        echo "vnet integration already configured for web app '$webApp'. Skipping ..."
    else
        echo "Integrating the web app '$webApp' with the VNet '$vnetName' and subnet '$subnetName'..."
        az webapp vnet-integration add --name $webApp --resource-group $resourceGroup --vnet $vnetName --subnet $subnetName
        echo "Complete."
    fi
}

