# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $pbi_pipelinename, $PreviousStage )

### ENVIRONMENT VARIABLES ============================================

$pipelineName = $pbi_pipelinename  # Pipeline Name
$stageOrder = $PreviousStage      # Previous Pipeline Stage: Development (0), Test (1).

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

# Trigger Deploy All to Next Stage ===================================

try { 
    # List Pipelines
    $pipelines = (Invoke-PowerBIRestMethod -Url "admin/pipelines"  -Method Get | ConvertFrom-Json).value
    # Find Pipeline ID
    $pipeline = $pipelines | Where-Object { $_.DisplayName -eq $pipelineName }
    if (!$pipeline) {
        Write-Error "##vso[task.logissue type=error]A pipeline with the requested name was not found"
        return
    }
    # API call
    $url = "pipelines/{0}/DeployAll" -f $pipeline.Id
    $body = @{ 
        sourceStageOrder = $stageOrder

        options          = @{
            allowCreateArtifact    = $TRUE
            allowOverwriteArtifact = $TRUE
        }
    } | ConvertTo-Json 
    $deployResult = Invoke-PowerBIRestMethod -Url $url  -Method Post -Body $body | ConvertFrom-Json
    "Operation ID: {0}" -f $deployResult.id
}
catch {
    $errmsg = Resolve-PowerBIError -Last
    $errmsg.Message
}
# Operation status
$operationId = $deployResult.id
try { 
    # Get Pipelines
    $pipelines = (Invoke-PowerBIRestMethod -Url "admin/pipelines"  -Method Get | ConvertFrom-Json).value
    # Find pipeline by pipelinename
    $pipeline = $pipelines | Where-Object { $_.DisplayName -eq $pipelineName }
    if (!$pipeline) {
        Write-Host "A pipeline with the requested name was not found"
        return
    }
    # Get details about the deploy operation
    $url = "pipelines/{0}/Operations/{1}" -f $pipeline.Id, $operationId
    $operation = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json    
    while ($operation.Status -eq "NotStarted" -or $operation.Status -eq "Executing") {
        # wait 5 seconds
        Start-Sleep -s 5
        $operation = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json
    }
    "Deployment completed with status: {0}" -f $operation.Status
}
catch {
    $errmsg = Resolve-PowerBIError -Last
    $errmsg.Message
}