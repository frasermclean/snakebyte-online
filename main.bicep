param location string = resourceGroup().location

var tags = {
  workload: 'network'
}

// virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'vnet-main'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'VirtualMachineSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }

  resource gatewaySubnet 'subnets' = {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }

  resource virtualMachineSubnet 'subnets' = {
    name: 'VirtualMachineSubnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
}

// network watcher
resource networkWatcher 'Microsoft.Network/networkWatchers@2022-05-01' = {
  name: 'nw-main'
  location: location
  tags: tags
}

// public ip for virtual network gateway
resource gatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-vng-main'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// virtual network gateway
resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-05-01' = {
  name: 'vng-main'
  location: location
  tags: tags
  properties: {
    enablePrivateIpAddress: false
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: false
    activeActive: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayPublicIpAddress.id
          }
          subnet: {
            id: virtualNetwork::gatewaySubnet.id
          }
        }
      }
    ]
  }
}

// local network gateway
resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2022-05-01' = {
  name: 'lgw-hive'
  location: location
  tags: tags
  properties: {
    gatewayIpAddress: '180.150.54.161'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.0/24'
      ]
    }
  }
}
