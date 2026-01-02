// modules/vnetNsg.bicep
// Minimal VNet + 2 subnets + 1 NSG (associated to both subnets)

targetScope = 'resourceGroup'

param vnetName string
param nsgName string
param location string
param tags object

@description('VNet address space, e.g. 10.11.0.0/16')
param vnetAddressPrefix string

@description('Shared subnet prefix, e.g. 10.11.1.0/24')
param subnetSharedPrefix string

@description('Private subnet prefix, e.g. 10.11.2.0/24')
param subnetPrivatePrefix string

var snetSharedName = 'snet-shared'
var snetPrivateName = 'snet-private'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    // No custom rules: defaults already deny inbound from Internet.
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: snetSharedName
        properties: {
          addressPrefix: subnetSharedPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: snetPrivateName
        properties: {
          addressPrefix: subnetPrivatePrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output nsgName string = nsg.name
output nsgId string = nsg.id
