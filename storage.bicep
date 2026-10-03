param location string = resourceGroup().location
param uniqueStorageName string = 'securestore${uniqueString(resourceGroup().id)}'

// 1. Create a Virtual Network to host secure resources
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'VNet-SecureStorage'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['172.16.0.0/16']
    }
    subnets: [
      {
        name: 'PrivateEndpoint-Subnet'
        properties: {
          addressPrefix: '172.16.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled' // Required flag for private endpoints
        }
      }
    ]
  }
}

// 2. Create the Storage Account with zero public internet entry paths
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: 'Standard_LRS' // Cost-effective locally redundant storage
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled' // Rejects all entry points over the public web
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }
}

// 3. Create a Private DNS Zone for Azure Blob Storage resolution
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

// 4. Link the Private DNS Zone directly to the Virtual Network
resource dnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-to-storage-vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// 5. Establish the Private Endpoint for the Blob sub-resource inside the subnet
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'PE-SecureBlobStorage'
  location: location
  properties: {
    subnet: {
      id: vnet.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'conn-to-blob-storage'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob' // Dictates we want to encapsulate blob traffic
          ]
        }
      }
    ]
  }
}

// 6. Connect Private Endpoint to Private DNS Zone for automatic IP mapping
resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
