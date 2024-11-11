# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$AKVSecret, $pbi_pipelinename, $Pipeline_Admin_Access_to, $Pipeline_Principal_Type)

### ENVIRONMENT VARIABLES ============================================

$pipelineName = $pbi_pipelinename
$UserPrincipal = $Pipeline_Admin_Access_to
$UserPrincipalType = $Pipeline_Principal_Type

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

### GRANT ACCESS TO DEPLOYMENT PIPELINE ==============================
Write-Host "Adding Access"

try {
    # Get pipeline with the same "pipelinename"
    $pipelines = Invoke-PowerBIRestMethod -Url "admin/pipelines" -Method Get | ConvertFrom-Json     
    $pipeline = $pipelines.Value | Where-Object displayName -eq $pipelineName
    if (!$pipeline) {
        Write-Error "##vso[task.logissue type=error]Pipeline with the name '$pipelineName' not found."
        return
    }
    # Add access to the Pipeline
    $updateAccessUrl = "pipelines/{0}/users" -f $pipeline.Id
    $updateAccessBody = @{ 
        identifier    = $UserPrincipal;
        accessRight   = "Admin";
        principalType = $UserPrincipalType;
    } | ConvertTo-Json
    Invoke-PowerBIRestMethod -Url $updateAccessUrl  -Method Post -Body $updateAccessBody
}
catch {
    $errmsg = Resolve-PowerBIError -Last
    $errmsg.Message
}