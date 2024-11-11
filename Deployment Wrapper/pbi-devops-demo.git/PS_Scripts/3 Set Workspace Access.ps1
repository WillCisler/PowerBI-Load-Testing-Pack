function FunctionName {
<#
.DESCRIPTION
This function adds the identified email user as admin of the workspace in power BI. It checks whether the use is already authorised.
.PARAMETER <Workspace_Principal_type>
This param must be 'user' for this case.

#>

# AZURE KEY VAULT SECRET AS PARAMETER ================================

Param([Parameter(Mandatory = $true)][String]$workspace_name, $Workspace_access_to, $Workspace_Principal_type, $Workspace_Access_type, $ServicePrincipalName)

### ENVIRONMENT VARIABLES ============================================

$workspaceName = $workspace_name
$UserPrincipal = $Workspace_access_to
$UserPrincipalType = $Workspace_Principal_type
$UserPrincipalAccess = $Workspace_Access_type
$ServicePrincipalName = $ServicePrincipalName

Write-Host "Workspace $workspace_name" 
Write-Host "UserPrincipal $UserPrincipal"
Write-Host "UserPrincipalType $UserPrincipalType"
Write-Host "Accesstype $Workspace_Access_type"
Write-Host "ServicePrincipalName $ServicePrincipalName"


### ADD ACCESS PERMISSIONS ===========================================

# Get workspace ID

Write-Host "Getting Workspace ID"
$workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization
$workspaceID = $workspace.Id
$Url1 = "admin/groups/{0}/users" -f $workspaceID
Write-Host "Workspace ID is $workspaceID"
Write-Host "url is $Url1"

# Set admin access for publisher principal.

Write-Host "Setting admin for publisher"

if ($PublisherEmail) {
    try {           
        Write-Host "try user-based set admin"
        $users = Invoke-PowerBIRestMethod -Url $Url1 -Method Get | ConvertFrom-Json      
        $user = $users.Value | Where-Object identifier -eq $PublisherEmail
        if (!$user) {
            $workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization
            Add-PowerBIWorkspaceUser -Id $workspace.Id -PrincipalType User -Identifier $PublisherEmail -AccessRight $UserPrincipalAccess  
            return
        }   
        Write-Warning "Group/User already added to workspace: $workspaceName."
    }
    catch {
        $errmsg = Resolve-PowerBIError -Last
        $errmsg.Message
    }
}
else {
    Write-Warning "No values registered on the PublisherEmail"
}

}