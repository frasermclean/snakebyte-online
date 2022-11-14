@description('Suffix to append to the NAT Gateway name')
param nameSuffix string

@description('Resource location')
param location string

@description('Resource tags to apply to all resources')
param tags object

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-${nameSuffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2022-05-01' = {
  name: 'ng-${nameSuffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}
