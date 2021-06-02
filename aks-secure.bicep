//
// Parameters
//
@description('The Azure region to use for this deployment')
param location string = resourceGroup().location

@description('The slug to be used as part of the resource names')
param name string = 'aks-secure'

@description('The DNS prefix for the API server')
param dnsPrefix string = 'aks-secure'

@minValue(1)
@maxValue(10)
@description('Number of cluster nodes')
param nodeCount int = 3

@description('Node virtual machine type')
param nodeSKU string = 'Standard_D2_v3'

@description('Kubernetes version')
param kubernetesVersion string = '1.20.5'

@description('Number to use for the second octet of the virtual network - 10.x.0.0/16 - This value will replace the x')
param virtualNetworkNumber int = 100

//
// Variables
//
var virtualNetworkName = '${name}-vnet'
var addressPrefix = '10.${virtualNetworkNumber}.0.0/16'
var aksSubnetName = '${name}-aks-subnet'
var aksSubnetPrefix = '10.${virtualNetworkNumber}.1.0/24'
var aksSubnetId = '${aks_vnet.id}/subnets/${aksSubnetName}'
var agicSubnetName = '${name}-agic-subnet'
var agicSubnetPrefix = '10.${virtualNetworkNumber}.2.0/24'
var agicSubnetId = '${aks_vnet.id}/subnets/${agicSubnetName}'
var aksIdentityName = '${name}-identity'
var aksIdentityId = '${aks_identity.id}'

//
// Create a managed identity
//

resource aks_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aksIdentityName
  location: location

}

//
// Create an Azure virtual network
//

resource aks_vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: aksSubnetPrefix
        }
      }
      {
        name: agicSubnetName
        properties: {
          addressPrefix: agicSubnetPrefix
        }
      }
    ]
  }
}

resource aks_cluster 'Microsoft.ContainerService/managedClusters@2021-03-01'=  {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentityId}' : {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'sys'
        count: nodeCount
        mode: 'System'
        vmSize: nodeSKU
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        vnetSubnetID: aksSubnetId
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          subnetId: agicSubnetId
        }
      }
    }
  }
}
