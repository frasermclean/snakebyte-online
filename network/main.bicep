@description('Name of the virtual network')
param networkName string = 'main'

@description('Azure resource location')
param location string = resourceGroup().location

@secure()
@description('Pre-shared connection key for the VPN connection.')
param connectionPreSharedKey string

@description('IP address of the local network gateway.')
param localNetworkGatewayAddress string

var tags = {
  workload: 'network'
}

module natGateway 'natGateway.bicep' = {
  name: 'natGateway'
  params: {
    nameSuffix: networkName
    location: location
    tags: tags
  }
}

// virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'vnet-${networkName}'
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
      {
        name: 'PersonalMediaServicesSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }

  resource gatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }

  resource virtualMachineSubnet 'subnets' existing = {
    name: 'VirtualMachineSubnet'
  }

  resource personalMediaServicesSubnet 'subnets' existing = {
    name: 'PersonalMediaServicesSubnet'
  }
}

// network watcher
resource networkWatcher 'Microsoft.Network/networkWatchers@2022-05-01' = {
  name: 'nw-${location}'
  location: location
  tags: tags
}

// public ip for virtual network gateway
resource gatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-vng-${networkName}'
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
  name: 'vng-${networkName}'
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
    gatewayIpAddress: localNetworkGatewayAddress
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.0/24'
      ]
    }
  }
}

// site-to-site vpn connection
resource connection 'Microsoft.Network/connections@2022-05-01' = {
  name: 'con-hive'
  location: location
  tags: tags
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    sharedKey: connectionPreSharedKey
    enableBgp: false
    virtualNetworkGateway1: {
      id: virtualNetworkGateway.id
      properties: {}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties: {}
    }
  }
}
