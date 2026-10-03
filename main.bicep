param location string = resourceGroup().location

// 1. Define Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'VNet-Hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'NVA-Subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// 2. Define Spoke Production VNet
resource prodVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'VNet-Spoke-Prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'App-Subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

// 3. Define Spoke Data VNet
resource dataVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'VNet-Spoke-Data'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.2.0.0/16']
    }
    subnets: [
      {
        name: 'Database-Subnet'
        properties: {
          addressPrefix: '10.2.1.0/24'
        }
      }
    ]
  }
}

// 4. VNet Peering: Hub to Prod
resource hubToProd 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: hubVnet
  name: 'Hub-to-SpokeProd'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: prodVnet.id
    }
  }
}

// 5. VNet Peering: Prod to Hub
resource prodToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: prodVnet
  name: 'SpokeProd-to-Hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

// 6. VNet Peering: Hub to Data
resource hubToData 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: hubVnet
  name: 'Hub-to-SpokeData'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: dataVnet.id
    }
  }
}

// 7. VNet Peering: Data to Hub
resource dataToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: dataVnet
  name: 'SpokeData-to-Hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

// 8. Custom Routing Table (UDR) to force traffic through the Hub
resource routeTableProd 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'RT-SpokeProd-to-Hub'
  location: location
  properties: {
    routes: [
      {
        name: 'Route-To-Data-Via-Hub'
        properties: {
          addressPrefix: '10.2.0.0/16' // Target Data Spoke
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.1.4' // Simulated Firewall/Router IP in Hub
        }
      }
    ]
  }
}
