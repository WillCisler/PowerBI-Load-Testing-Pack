# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $workspace_name, $capacityname, $pbi_pipelinename, $TargetStage)

### ENVIRONMENT VARIABLES ============================================

$workspaceName = $workspace_name  # This will be automatically adjusted for every development stage (dev, test, prod) with the appropriate environment variables.
$CapacityName = $capacityname
$PipelineName = $pbi_pipelinename
$TargetStage = $TargetStage     # (0) = Dev, (1) = Test, (2) = Prod

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

### SET DEPLOYMENT STAGE TO WORKSPACE ================================

# GET WORKSPACE ID
Write-Host "Getting Workspace ID"
$workspace = Get-PowerBIWorkspace -Name $workspaceName
$workspaceID = $workspace.Id

# GET PIPELINE ID
Write-Host "Getting pipeline ID"
$pipelines = (Invoke-PowerBIRestMethod -Url "admin/pipelines"  -Method Get | ConvertFrom-Json).value
$pipeline = $pipelines | Where-Object { $_.DisplayName -eq $PipelineName }
$pipelineID = $pipeline.id

### SET WORKSPACE TO PIPELINE STAGE

$Url1 = "pipelines/{0}/stages" -f $pipelineID
try {
    $dp_workspaces = Invoke-PowerBIRestMethod -Url $Url1 -Method Get | ConvertFrom-Json      
    $dp_workspace = $dp_workspaces.Value | Where-Object order -eq $TargetStage
    $dp_workspace_id = $dp_workspace.workspaceId
    $dp_workspace_name = $dp_workspace.workspaceName
    if ($dp_workspace.workspaceId -eq $workspaceID) {
        Write-Warning "##vso[task.logissue type=warning]This workspace is already attached to the selected deployment stage."
        Write-Host "Workspace ID: $dp_workspace_id"
        Write-Host "Workspace Name: $dp_workspace_name" 
        return
    }
    
    Write-Host "Setting workspace into the Pipeline"

    $Urlpipe = "pipelines/{0}/stages/{1}/assignWorkspace" -f $pipelineId, $TargetStage
    $Body = @{ 
        workspaceId = $workspaceID;
    } | ConvertTo-Json
    Invoke-PowerBIRestMethod -Url $Urlpipe -Method Post -Body $body
    
}
catch {
    $errmsg = Resolve-PowerBIError -Last
    $errmsg.Message
}
