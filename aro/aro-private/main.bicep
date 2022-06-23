@description('Location')
param location string = resourceGroup().location

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aro-${uniqueString(uniqueSeed)}'

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
param pullSecret string

@description('ARO vNet Address Space')
param virtualNetworkCidr string = '10.100.0.0/16'

@description('Control plane node subnet address space')
param controlPlaneSubnetCidr string = '10.100.0.0/23'

@description('Worker node subnet address space')
param nodeSubnetCidr string = '10.100.2.0/23'

param domain string = name

@description('Worker node subnet address space')
param jumpboxSubnetCidr string = '10.100.2.0/23'

@description('Master Node VM Type')
param controlPlaneVmSize string = 'Standard_D8s_v3'

@description('Worker Node VM Type')
param nodeVmSize string = 'Standard_D4s_v3'

@description('Worker Node Disk Size in GB')
@minValue(128)
param nodeVmDiskSize int = 128

@description('Number of Worker Nodes')
@minValue(3)
param nodeCount int = 3

@description('Cidr for Pods')
param podCidr string = '10.128.0.0/14'

@metadata({
  description: 'Cidr of service'
})
param serviceCidr string = '172.30.0.0/16'

@description('Tags for resources')
param tags object = {
  env: 'Dev'
  dept: 'Ops'
}

@description('Api Server Visibility')
@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string = 'Public'

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string = 'Public'

@description('The Application ID of an Azure Active Directory client application')
param clientId string

@description('The Object ID of an Azure Active Directory client application')
param objectId string

@description('The secret of an Azure Active Directory client application')
@secure()
param clientSecret string

@description('The ObjectID of the Resource Provider Service Principal')
param rpObjectId string

var contribRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

module aroNetwork 'modules/network.bicep' = {
  name: '${deployment().name}--aroNetwork'
  params: {
    name: name
    location: location
    virtualNetworkCidr: virtualNetworkCidr
    controlPlaneSubnetCidr: controlPlaneSubnetCidr
    nodeSubnetCidr: nodeSubnetCidr
    contribRole: contribRole
    objectId: objectId
    rpObjectId: rpObjectId
  }
}

module aroCluster 'modules/aro.bicep' = {
  name: '${deployment().name}--aroCluster'
  params: {
    name: name
    location: location
    controlPlaneSubnetId: aroNetwork.outputs.controlPlaneSubnetId
    nodeSubnetId: aroNetwork.outputs.nodeSubnetId
    clientId: clientId
    clientSecret: clientSecret
    apiServerVisibility: apiServerVisibility
    ingressVisibility: ingressVisibility
    pullSecret: pullSecret
    controlPlaneVmSize: controlPlaneVmSize
    nodeVmSize: nodeVmSize
    nodeVmDiskSize: nodeVmDiskSize
    nodeCount: nodeCount
    domain: domain
    podCidr: podCidr
    serviceCidr: serviceCidr
  }

  dependsOn: [
    aroNetwork
  ]
}
