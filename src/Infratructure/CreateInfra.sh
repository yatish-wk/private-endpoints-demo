#!/bin/bash

# fail script when any command fails
set -e

source ./lib/vars.sh
source ./lib/createfunctions.sh

# create resource group
create_resource_group $locEast

# RGs to hold private dns zones
create_dns_resource_group $locEast
create_dns_resource_group $locWest

# web app
create_appservice_plan $locEast
create_appservice_plan $locWest
create_web_app $locEast
create_web_app $locWest

# cosmos
create_cosmos_account
create_cosmos_db
create_container "Items"

# sql
create_sql_server $locEast
create_sql_server $locWest
create_sql_db $locEast    # create db only in east, it will be replicated to west by failover group
create_failover_group $locEast $locWest

# storage account
create_storage_account $locEast

# service bus
create_service_bus_namespace $locEast
create_service_bus_namespace $locWest

# function app
create_function_app $locEast
create_function_app $locWest

# vnet
create_vnet $locEast "10.6.0.0/16" "10.6.0.0/24" "10.6.1.0/24"
create_vnet $locWest "10.7.0.0/16" "10.7.0.0/24" "10.7.1.0/24"

# peering vnets should not be necessary because every private-endpoint, irrespective of 
# primary or secondary region or target resource, should always resolve to a local vnet address
# peer_vnets

vnet_integration $locEast
vnet_integration $locWest

echo "Completed creating infrastructure!"

echo "setting web app configuration..."
set_webapp_app_setting $locEast "COSMOS_ENDPOINT" $out_cosmosEndpointUrl
set_webapp_app_setting $locWest "COSMOS_ENDPOINT" $out_cosmosEndpointUrl
set_webapp_app_setting $locEast "COSMOS_KEY" $out_primaryKey
set_webapp_app_setting $locWest "COSMOS_KEY" $out_primaryKey

set_webapp_app_setting $locEast "STORAGE_ENDPOINT" $out_storageConnectionString
set_webapp_app_setting $locWest "STORAGE_ENDPOINT" $out_storageConnectionString

set_webapp_conn_string $locEast "SQLAzure" "PoCContext" "$out_sqlConnectionString"
set_webapp_conn_string $locWest "SQLAzure" "PoCContext" "$out_sqlConnectionString"

busConString="out_busConnectionString_$locEast"
set_webapp_conn_string $locEast "Custom" "PoCBus" ${!busConString}
busConString="out_busConnectionString_$locWest"
set_webapp_conn_string $locWest "Custom" "PoCBus" ${!busConString}

echo "Completed web app configuration!"

