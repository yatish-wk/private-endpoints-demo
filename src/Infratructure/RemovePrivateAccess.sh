#!/bin/bash

# fail script when any command fails
set -e

source ./lib/vars.sh
source ./lib/network.sh
source ./lib/dns.sh
source ./lib/privateendpoints.sh

# delete cosmosdb private zone dns to vnet link
delete_link_private_zone_to_vnet $cosmosZoneName $locEast
delete_link_private_zone_to_vnet $cosmosZoneName $locWest

# delete sql private zone dns to vnet link
delete_link_private_zone_to_vnet $sqlZoneName $locEast
delete_link_private_zone_to_vnet $sqlZoneName $locWest

# delete storage private zone dns to vnet link
delete_link_private_zone_to_vnet $storageZoneName $locEast
delete_link_private_zone_to_vnet $storageZoneName $locWest

# delete servicebus private zone dns to vnet link
delete_link_private_zone_to_vnet $servicebusZoneName $locEast
delete_link_private_zone_to_vnet $servicebusZoneName $locWest

# enable public access
enable_public_access_cosmos

enable_public_access_sql $locEast
enable_public_access_sql $locWest

enable_public_access_storage

enable_public_access_bus $locEast
enable_public_access_bus $locWest
