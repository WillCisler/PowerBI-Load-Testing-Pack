# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $pbi_pipelinename, $PreviousStage)

### ENVIRONMENT VARIABLES ============================================

$pipelineName = $pbi_pipelinename  # Pipeline Name
$stageOrder = $PreviousStage       # Previous Pipeline Stage: Development (0), Test (1).

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

### Refresh recently deployed datasets ===============================

try { 

  # GET PIPELINE DETAILS
  Write-Host "Getting Pipeline details..."
  $pipelines = (Invoke-PowerBIRestMethod -Url "admin/pipelines"  -Method Get | ConvertFrom-Json).value
  $pipeline = $pipelines | Where-Object { $_.DisplayName -eq $pipelineName }
  if (!$pipeline) {
    Write-Error "##vso[task.logissue type=error]Pipeline not found with the name: $pipelineName"
    return
  } 
    
  # GET TARGET WORKSPACE ID
  Write-Host "Getting target workspace details..."
  $Target_Workspace_Url = "admin/pipelines/{0}?`$expand=stages" -f $pipeline.id
  $Piepeline_Workspaces = Invoke-PowerBIRestMethod -Url $Target_Workspace_Url  -Method Get  | ConvertFrom-Json
  if ($stageOrder -eq 1) { $targetorder = 2 } elseif ($stageOrder -eq 0) { $targetorder = 1 } else { $null }
  $Target_Workspace = $Piepeline_Workspaces.stages | Where-Object order -eq $targetorder
  $Target_Workspace_id = $Target_Workspace.workspaceId
  if (!$Target_Workspace_id) {
    Write-Error "##vso[task.logissue type=error]Target Workspace ID not found in the Pipeline: $pipeline" 
    return
  } 
  Write-Host "Found: $Target_Workspace_id"

  # GET LAST DEPLOY OPERATION ID
  Write-Host "Getting operation ID from the last Deploy operation..."
  $url = "pipelines/{0}/operations" -f $pipeline.Id
  $operations = (Invoke-PowerBIRestMethod -Url $url  -Method Get  | ConvertFrom-Json).value   
  $Last_Operation_details = $operations | Where-Object type -eq Deploy | Sort-Object lastUpdatedTime -Descending | Select-Object -First 1
  $OperationID = $Last_Operation_details.id
    
  if (!$OperationID) {
    Write-Error "##vso[task.logissue type=error]Deploy operation ID not found. Here is a list of the last registered operations:"
    $operations | Sort-Object lastUpdatedTime -Descending 
    return
  } 
  Write-Host "Found: $OperationID"

  # DATASETS DEPLOYED ON THE LAST OPERATION
  Write-Host "Getting the Datasets deployed on the last operation..."
  $url1 = "pipelines/{0}/operations/{1}" -f $pipeline.Id, $OperationID
  $operation = Invoke-PowerBIRestMethod -Url $url1  -Method Get  | ConvertFrom-Json
  $DatasetsDeployed = $operation.executionPlan.steps | Where-Object type -eq datasetdeployment | Where-Object status -eq Succeeded

  if (!$DatasetsDeployed) {
    Write-Error "##vso[task.logissue type=error]There were no deployed datasets found on the last deploy operation."
    return
  } 

  $Source_Datasets = $DatasetsDeployed.sourceAndTarget.source

  Write-Host "::::::Starting refresh requests for each Dataset:::::"

  foreach ($Source_datasetID in $Source_Datasets) {
        
    # Get dataset name from previous stage
    $UrlDataset = "admin/datasets/{0}" -f $Source_datasetID
    $Source_Dataset = Invoke-PowerBIRestMethod -Url $UrlDataset -Method Get | ConvertFrom-Json           
    $Dataset_name = $Source_Dataset.name
    Write-Host "Dataset name from previous stage: $Dataset_name"

    # Get the dataset ID form the new stage
    $Url_Update = "groups/{0}/datasets" -f $Target_Workspace_id
    $new_dataset = (Invoke-PowerBIRestMethod -Url $Url_Update -Method Get | ConvertFrom-Json).value
    $new_dataset_id = ($new_dataset | Where-Object name -eq $Dataset_name).id
    Write-Host "Dataset ID from the new stage: $new_dataset_id"

    # Refresh dataset in the new stage       
    $Url_Refresh = "datasets/{0}/refreshes" -f $new_dataset_id
    $Body = @{
      notifyOption = "MailOnFailure";
    } | ConvertTo-Json
    $Refresh_dataset = Invoke-PowerBIRestMethod -Url $Url_Refresh -Method Post -Body $Body
    $Refresh_dataset
    Write-Host "Refresh request sent to dataset: $Dataset_name ID: $new_dataset_id"
  }         
}
catch {
  $errmsg = Resolve-PowerBIError -Last
  $errmsg.Message
}