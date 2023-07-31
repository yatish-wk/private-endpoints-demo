function create_private_dns_zone() {
    local privateDnsZoneName=$1
    local location=$2
    local resourceGroup="${dnsResourceGroup}-${location}"

    # Check if private DNS zone exists and create it
    if az network private-dns zone show \
            --name $privateDnsZoneName \
            --resource-group $resourceGroup >/dev/null 2>&1; then
        echo "Private DNS zone '$privateDnsZoneName' already exists. Skipping private DNS zone creation."
    else
        # Create the private DNS zone
        echo "Creating private DNS zone '$privateDnsZoneName' in resource group ${resourceGroup}."
        az network private-dns zone create --name $privateDnsZoneName --resource-group $resourceGroup
        echo "Private DNS zone '$privateDnsZoneName' has been created."
    fi
}

function link_private_zone_to_vnet() {
    local privateDnsZoneName=$1
    local location=$2
    local vnetResourceGroup=$resourceGroup
    local resourceGroup="${dnsResourceGroup}-${location}"
    local linkName="cosmos-link-${vnetName}"
    
    # link zone to vnet
    if az network private-dns link vnet show \
            --zone-name $privateDnsZoneName \
            --name $linkName \
            --resource-group $resourceGroup >/dev/null 2>&1; then
        echo "Link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName' already exists. Skipping link creation."
    else
        local vnetId=$(az network vnet show \
                            --name $vnetName \
                            --resource-group $vnetResourceGroup \
                            --query id \
                            --output tsv)
        
        # Create the link between the private DNS zone and the virtual network
        echo "Creating link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName'..."
        MSYS_NO_PATHCONV=1 az network private-dns link vnet create --name $linkName --resource-group $resourceGroup --zone-name $privateDnsZoneName --virtual-network $vnetId --registration-enabled false 
        echo "Link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName' has been created."
    fi
}

function delete_link_private_zone_to_vnet() {
    local privateDnsZoneName=$1
    local location=$2
    local vnetResourceGroup=$resourceGroup
    local resourceGroup="${dnsResourceGroup}-${location}"
    local linkName="cosmos-link-${vnetName}"
    
    # delete link zone from vnet
    if az network private-dns link vnet show \
            --zone-name $privateDnsZoneName \
            --name $linkName \
            --resource-group $resourceGroup >/dev/null 2>&1; then
        # Delete the link between the private DNS zone and the virtual network
        echo "Deleting link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName'..."
        MSYS_NO_PATHCONV=1 az network private-dns link vnet delete --name $linkName --resource-group $resourceGroup --zone-name $privateDnsZoneName
        echo "Link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName' has been deleted."
    else
        echo "No Link between private DNS zone '$privateDnsZoneName' and virtual network '$vnetName' already exists. Skipping link creation."
    fi
}

function create_private_dns_zone_group() {
    local privateDnsZoneName=$1
    local privateEndpointName=$2
    local location=$3
    
    # zone group - is link back from private endpoint to DNS zone
    local zoneGroupName="default"
    local zoneConfigName="privatelink-config"
    local dnsResourceGroup="${dnsResourceGroup}-${location}"
    local exists=$(az network private-endpoint dns-zone-group show \
                        --name $zoneGroupName \
                        --endpoint-name $privateEndpointName \
                        --resource-group $resourceGroup \
                        --output tsv 2>/dev/null)

    # Check if the zone group for the private endpoint already exists
    if [ -n "$exists" ]; then
        echo "DNS zone group $zoneGroupName already exists for private endpoint $privateEndpointName."
    else
        local dnsZoneId=$(az network private-dns zone show \
                                --name $privateDnsZoneName \
                                --resource-group $dnsResourceGroup \
                                --query id \
                                --output tsv)

        echo "Creating zone group $zoneGroupName for private endpoint $privateEndpointName..."
        # Create a new DNS zone group for the private endpoint
        MSYS_NO_PATHCONV=1 az network private-endpoint dns-zone-group create \
                                --resource-group $resourceGroup \
                                --endpoint-name $privateEndpointName \
                                --name $zoneGroupName \
                                --private-dns-zone $dnsZoneId \
                                --zone-name $zoneConfigName

        echo "DNS zone group $zoneGroupName created for private endpoint $privateEndpointName."
    fi
}
