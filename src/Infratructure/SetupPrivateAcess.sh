#!/bin/bash

# fail script when any command fails
set -e

source ./lib/vars.sh
source ./lib/network.sh
source ./lib/dns.sh
source ./lib/privateendpoints.sh

# creates priavate endpoints
create_endpoint_cosmos $locEast
create_endpoint_cosmos $locWest

# to support failover group, each sql server has private endpoints in both vnets
create_endpoint_sql $locEast $locEast
create_endpoint_sql $locEast $locWest
create_endpoint_sql $locWest $locWest
create_endpoint_sql $locWest $locEast


create_endpoint_storage $locEast
create_endpoint_storage $locWest

create_endpoint_bus $locEast
create_endpoint_bus $locWest

# disable public access
disable_public_access_cosmos

disable_public_access_sql $locEast
disable_public_access_sql $locWest

disable_public_access_storage

disable_public_access_bus $locEast
disable_public_access_bus $locWest
