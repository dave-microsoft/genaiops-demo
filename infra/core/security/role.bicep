metadata description = 'Creates a role assignment for a service principal.'
param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param roleDefinitionId string

// resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
//   properties: {
//     principalId: principalId
//     principalType: principalType
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
//   }
// }
resource role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: 'checkOrCreateRoleAssignment'
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.30.0'
    scriptContent: '''
      principalId=${principalId}
      roleDefinitionId=${roleDefinitionId}
      scope=${scope}

      existingRoleAssignment=$(az role assignment list --assignee $principalId --role $roleDefinitionId --scope $scope --query "[].id" -o tsv)

      if [ -z "$existingRoleAssignment" ]; then
        az role assignment create --assignee $principalId --role $roleDefinitionId --scope $scope
      else
        echo "Role assignment already exists."
      fi
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
