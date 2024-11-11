# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $workspace_name, $CapacityName)

### ENVIRONMENT VARIABLES ============================================

$workspaceName = $workspace_name       # This will be automatically adjusted for every development stage (dev, test, prod) with the appropriate environment variables.
#$CapacityName = $CapacityName #capacityname

Write-Host "Checking $CapacityName exists"
#Write-Host "Checking $(capacityName) exists"

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
  Write-Error "##vso[task.logissue type=warning] error 33 No values registered on the PublisherEmail or APP_ID variables on the YAML pipeline. Also please check if the AKV Secret and variables are properly configured."
}

### ADD WORKSPACE TO PREMIUM CAPACITY ================================

Write-Host "Getting capacity ID"
$capacities = Invoke-PowerBIRestMethod -Url "admin/capacities" -Method Get | ConvertFrom-Json     
$capacity = $capacities.Value | Where-Object displayName -eq $CapacityName
$capacityId = $capacity.id

Write-Host "ID is: $capacityId"

Write-Host "Adding workspace $workspaceName to premium capacity $CapacityName"
$workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization
$Url = "groups/{0}/AssignToCapacity" -f $workspace.Id
$Body = @{ 
  capacityId = $capacityId;
} | ConvertTo-Json

Write-Host "$Url"
Write-Host "$Body"

Invoke-PowerBIRestMethod -Url $Url -Method Post -Body $Body
