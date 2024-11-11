# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $pbi_pipelinename)

### ENVIRONMENT VARIABLES ============================================
Write-Host "Start process to create pipeline: $pbi_pipelinename"

$displayName = $pbi_pipelinename
$description = $displayName   # The pipeline description will be the same as it's name. It can be changed later on the Power BI portal.

### DYNAMIC AUTHENTICATION ===========================================

$AppId = $ENV:APP_ID
$TenantId = $ENV:TENANT_ID
$PublisherEmail = $ENV:PublisherEmail

Write-Host "Auth"

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

### CREATE DEPLOYMENT PIPELINE =======================================
Write-Host "Create Pipeline"

try {
  $pipelines = (Invoke-PowerBIRestMethod -Url "admin/pipelines"  -Method Get | ConvertFrom-Json).value
  Write-Host "Grabbed List of pipelines"
  $pipeline = $pipelines | Where-Object { $_.DisplayName -eq $displayName }
  Write-Host "Filtered List of Pipelines for this one: $displayName"
  if (!$pipeline) {            
    $activityId = New-Guid
    Write-Host "Activity ID: $activityId"
    $body = @{ 
      displayName = $displayName
      description = $description
    } | ConvertTo-Json
    Write-Host "Sending request to create new Deployment Pipeline."
    Write-Host "Request Body- $body"
    $newPipeline = Invoke-PowerBIRestMethod -Url "pipelines" -Method Post -Body $body | ConvertFrom-Json
    Write-Host "New deployment pipeline successfully created - Id = $($newPipeline.Id)"
    return
  }
  $current_pipeline = $pipeline.id    
  Write-Warning "##vso[task.logissue type=warning]Pipeline named '$displayName' already exists. Pipeline ID: $current_pipeline"   

}
catch {
  $err = Resolve-PowerBIError -Last
  Write-Error $err.Message
}