param logName string
param location string
param logAnalytics_resourceId string
@secure()
param spn_clientId string
@secure()
param spn_clientSecret string
param spn_tenantId string

resource customLog 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'CustomLog_${ logName }'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.37.0'
    timeout: 'PT3M'
    scriptContent: 'az login --service-principal -u "${ spn_clientId }" -p "${ spn_clientSecret }" -t "${ spn_tenantId }"; az rest --method put --uri ${ logAnalytics_resourceId }/tables/${ logName }_CL?api-version=2021-12-01-preview --body "{\'properties\':{\'schema\':{\'name\':\'${ logName }_CL\',\'columns\':[{\'name\':\'TimeGenerated\',\'type\':\'DateTime\'},{\'name\':\'RawData\',\'type\':\'String\'}]}}}"'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
}
