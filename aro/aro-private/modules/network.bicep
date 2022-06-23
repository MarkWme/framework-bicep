param name string
param location string
param virtualNetworkCidr string
param controlPlaneSubnetCidr string
param nodeSubnetCidr string
param contribRole string
param objectId string
param rpObjectId string

resource aroVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: '${name}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCidr
      ]
    }
    subnets: [
      {
        name: '${name}-control-subnet'
        properties: {
          addressPrefix: controlPlaneSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: '${name}-node-subnet'
        properties: {
          addressPrefix: nodeSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
        }
      }
    ]
  }
  resource controlPlaneSubnet 'subnets' existing = {
    name: '${name}-control-subnet'
  }

  resource nodeSubnet 'subnets' existing = {
    name: '${name}-node-subnet'
  }
}

output controlPlaneSubnetId string = aroVirtualNetwork::controlPlaneSubnet.id
output nodeSubnetId string = aroVirtualNetwork::nodeSubnet.id


resource aroVirtualNetworkSPNContributorRole 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(aroVirtualNetwork.id, objectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: objectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}

resource aroVirtualNetworkRPContributorRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(aroVirtualNetwork.id, rpObjectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}
