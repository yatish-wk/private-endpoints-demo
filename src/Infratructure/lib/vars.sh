resourceGroup="private-endpoints-poc"
locEast="EastUS"
locWest="WestUS"

dnsResourceGroup="private-endpoints-poc-dnszone"

pocName="prvend"
cosmosAccount="cosmos-${pocName}"
cosmosDatabase="ToDoList"

webApp="pocapp-${pocName}"
appSvcPlan="appsvcplan-${webApp}"

sqlServer="sqlserver-${pocName}"
sqlDb="swsdb"
sqlLogin="azureuser"
sqlPass="Pa33w0rd"
sqlFailoverGroup="global-${sqlServer}"

storageAccount="storage${pocName}"     # storage a/c name cannot have hyphen

serviceBusNamespace="servicebus-${pocName}"
queueName="testqueue"

functionApp="functionapp-${pocName}"

vnetName="vnet-${pocName}"

privateEndpointName="endpoint-${pocName}"

cosmosZoneName="privatelink.documents.azure.com"
sqlZoneName="privatelink.database.windows.net"
storageZoneName="privatelink.blob.core.windows.net"
servicebusZoneName="privatelink.servicebus.windows.net"
