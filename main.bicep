//https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-bicep?tabs=CLI
@description('Username for the Virtual Machine.')
param adminUserName string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPassword string

@description('environment of this resource.')
param project string

@description('environment of this resource.')
param environment string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vm_ansible_size string = 'Standard_B2ms'

@description('Name of existing VNet RG')
param vnetRG string 

@description('Name of existing VNet')
param vnetName string 

@description('Name of existing subnet in the virtual network')
param vm_ansible_subnetName string = 'default'

var vmName = '${project}${environment}cfgvm'
var networkInterfaceName = '${vmName}-nic'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUserName}/.ssh/authorized_keys'
        keyData: adminPassword
      }
    ]
  }
}
var cloudInit = base64(loadTextContent('../../cloud_init/rhel_azdo_poolagent.yml'))

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId(subscription().subscriptionId,vnetRG,'Microsoft.Network/virtualNetworks/subnets', vnetName, vm_ansible_subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  tags: {
    Role: 'Ansible'
    uptime: 'ignore'
  }
  properties: {
    hardwareProfile: {
      vmSize: vm_ansible_size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '86-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
      customData: cloudInit
    }
  }
}
