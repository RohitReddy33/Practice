# CloudInit Scripts
CloudInit (https://cloud-init.io/) scripts are passed as "custom data" to deployments for Linux VMs (ARM, Bicep or Terraform) and perform initial configuration such as network config, user/group creation, package installation, etc.

**Example Bicep usage:**
```
var  cloudInit = base64(loadTextContent('../../cloud_init/rhel_azdo_poolagent.yml'))

resource  vm  'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  properties {
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
      customData: cloudInit
    }
  }
}
```
#### Notes:
- CloudInit works across all cloud providers but may vary between distributions.
- If a new CloudInit script is passed to an existing VM the deployment will fail. They should be considered run-once scripts.
- Scripts may be debugged during development by looking at /var/log/cloud-init-output.log (or by simply viewing the VM serial log immediately after deployment).