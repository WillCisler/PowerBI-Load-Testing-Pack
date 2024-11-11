# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $workspace_name)

### ENVIRONMENT VARIABLES ============================================

$workspaceName = $workspace_name 

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

### UPLOAD ALL PBIX FILES IN FOLDER ==================================

# GET WORKSPACE ID
Write-Host "Getting Workspace ID"
$workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization
$workspaceID = $workspace.Id
$workspaceID

# UPLOAD PBIX FILES
$searchedFiles = Get-ChildItem -Path .\*.pbix -Recurse
foreach ($foundFile in $searchedFiles) {
  $directory = $foundFile.DirectoryName
  $file = $foundFile.Name
  $filePath = "$directory/$file"
  Write-Host "Publishing PBIX file to Power BI... Source folder: $filePath"
  $pbixFilePath = $filePath
  $import = New-PowerBIReport -Path $pbixFilePath -Workspace $workspace -ConflictAction CreateOrOverwrite
  $import | Select-Object
}