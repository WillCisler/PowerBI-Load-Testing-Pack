# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $workspace_name)

### ENVIRONMENT VARIABLES ============================================

$workspaceName = $workspace_name    # This will be automatically adjusted for every development stage (dev, test, prod) with the appropriate environment variables.

### DYNAMIC AUTHENTICATION ===========================================

$AppId = $ENV:APP_ID
$TenantId = $ENV:TENANT_ID
$PublisherEmail = $ENV:PublisherEmail

if ($AppId) {
  Write-Host "Authenticating with Service Principal. App ID: $AppId"
  $PbiSecurePassword = ConvertTo-SecureString $AKVSecret -Force -AsPlainText
  $PbiCredential = New-Object Management.Automation.PSCredential($AppId, $PbiSecurePassword)
  Connect-PowerBIServiceAccount -ServicePrincipal -TenantId $TenantId -Credential $PbiCredential
}
elseif ($PublisherEmail) {
  Write-Host "Authenticating with User Email: $PublisherEmail"
  $password = $AKVSecret | ConvertTo-SecureString -asPlainText -Force
  $username = $PublisherEmail
  $credential = New-Object System.Management.Automation.PSCredential($username, $password)
  Connect-PowerBIServiceAccount -Credential $credential
}
else {
  Write-Error "##vso[task.logissue type=warning]No values registered on the PublisherEmail or APP_ID variables on the YAML pipeline. Also please check if the AKV Secret and variables are properly configured."
}

### ADD NEW WORKSPACE ================================================

Write-Host "Checking if workspace name exists"
Write-Host "Name: $workspaceName"
Write-Host "ENV: $env:workspace "

$workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization

if ($workspace) {
  Write-Warning "##vso[task.logissue type=warning]The workspace named $workspaceName already exists"
}
else {
  Write-Host "Creating new workspace named $workspaceName"
  $workspace = New-PowerBIGroup -Name $workspaceName
}
