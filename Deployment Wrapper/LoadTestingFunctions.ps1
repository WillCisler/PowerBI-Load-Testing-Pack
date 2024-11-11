function DeployLoadTestingVm {

    <#
    .DESCRIPTION
    This Script Builds all the neccesary componet to run a Data Science Virtual machine and connect to it via RDF

    Some notes tbd

    Here is a PowerShell script that creates a new Azure virtual machine using the Windows 10 image:
#>
    param (
        [string]$resourceGroup = "pbiLoadTesting",
        [string]$location = "uksouth",
        [string]$vmName = "myDSVM",
        [string]$vmSize = "Standard_DS3_v2",
        [string]$offerName = "Windows-10", #"windows-data-science-vm",
        [string]$skuName = "win10-21h2-pro-g2", #"windows2016",
        [string]$version = "latest", #"20.01.10",
        [string]$publisherName = "MicrosoftWindowsDesktop", ##"microsoft-ads",
        [string]$productName = "Windows-10", #"windows-data-science-vm",
        [string]$planName = "windows2016",
        [Parameter(Mandatory = $true)]
        [string]$adminEmail
    )


    Start-Sleep -Seconds 2.0

    # Create user object
    $cred = Get-Credential -Message "Enter a username and password for the virtual machine."

    # Create a resource group
    Write-Host(" Creating Resource Group")
    New-AzResourceGroup -Name $resourceGroup -Location $location

    Write-Host(" Creating a subnet configuration")
    # Create a subnet configuration
    $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

    # Create a virtual network
    Write-Host(" Creating a virtual network")
    $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
        -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

    # Create a public IP address and specify a DNS name
    Write-Host(" Creating a public IP address and specify a DNS name")
    $pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
        -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

    # Creat an inbound network security group rule for port 3389
    Write-Host(" Creating an inbound network security group rule for port 3389")
    $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
        -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
        -DestinationPortRange 3389 -Access Allow

    # Create a network security group
    Write-Host(" Creating a network security group")
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
        -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP

    # Create a virtual network card and associate with public IP address and NSG
    Write-Host(" Creating a virtual network card and associate with public IP address and NSG")
    $nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
        -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

    # Create a virtual machine configuration
    Write-Host(" Creating a virtual machine configuration")
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $cred

    # Set the Marketplace image
    Write-Host(" Set the Marketplace image")

    $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version $version

    # Set the Marketplace plan information
    Write-Host(" Set the Marketplace plan information")

    <#Plan not needed for Win10 machine but required for windows-data-science-vm#>
    if ($offerName == 'windows-data-science-vm') {
        $vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $publisherName -Product $productName -Name $planName
    }

    #NIC
    Write-Host("Set NIC for VM")
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

    # Create a virtual machine
    Write-Host(" Creating virtual machine")
    $newVM = New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
    Write-Host $newVM

    # This code is meant to print the link to new VM for ease of use
    Connect-AzureAD
    $tenantDetail = Get-AzureADTenantDetail
    $subscription = Get-AzSubscription
    Write-Host "https://portal.azure.com/#$($tenantDetail.VerifiedDomain.Name)/resource/subscriptions/$($subscription.Id)/resourceGroups/$($resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($vmName)/overview"


}


function CreatePowerBISkuForTesting {
    <#
    .DESCRIPTION
    This Script Builds then pauses an Embedded Power BI SKU

    Some notes tbd
#>
    param (
        [string]$resourceGroup = "rg-pbi-premium-for-load-testing",
        [string]$location = "uksouth",
        [string]$capacityName = "capacityforloadtesting",
        [string]$pbiSKU = "A1",
        [Parameter(Mandatory = $true)]
        [string]$adminEmail #= "admin@MngEnv789898.onmicrosoft.com"
    )

    Start-Sleep -Seconds 2.0

    # Variables for common values
    Write-Host("RG:{0}" -f $resourceGroup)
    Write-Host("AZ Region:{0}" -f $location)
    Write-Host("Name:{0}" -f $capacityName)
    Write-Host("Sku:{0}" -f $pbiSKU)
    Write-Host("admin{0}" -f $adminEmail)

    # Create a resource group
    New-AzResourceGroup -Name $resourceGroup -Location $location
    New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroup -Name $capacityName -Location $location -Sku $pbiSKU -Administrator $adminEmail
    Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroup
    Suspend-AzPowerBIEmbeddedCapacity -Name $capacityName -ResourceGroupName $resourceGroup -PassThru

    $capacity = Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroup


    Write-Host ("Capacity '{0}' was created in Resource Group '{1}' and its state is '{2}'" -f $capacity.Name, $capacity.ResourceGroup, $capacity.State)
}


function ResumePowerBiSku {
    <#
    .DESCRIPTION
    This Script resumes the an Embedded Power BI SKU
#>
    param (
        [string]$resourceGroup = "rg-pbi-premium-for-load-testing",
        [string]$capacityName = "capacityforloadtesting"
    )

    Write-Host Resume-AzPowerBIEmbeddedCapacity -Name $capacityName -ResourceGroupName $resourceGroup -PassThru
    $capacity = Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroup
    Write-Host ("'{0}' Capacity in Resource Group '{1}' is '{2}'" -f $capacity.Name, $capacity.ResourceGroup, $capacity.State)
}


function TestPowerBiSku {
    param (
        [string]$capacityName = "capacityforloadtesting"
    )
    Test-AzPowerBIEmbeddedCapacity -Name $capacityName
}


function InstallPowerBiCommandModules {
    <#
    .DESCRIPTION
    This Script resumes the an Embedded Power BI SKU

#>

    ### INSTALL POWER BI MANAGEMENT MODULES ==========================================
    
    Write-Host "Verifying modules installation..."
    
    if (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt) {
        Write-Host "Modules already installed."
    } 
    else {
        Write-Host "Installing Power BI Management Modules."
        Install-Module -Name MicrosoftPowerBIMgmt -Force -Verbose -Scope CurrentUser
        Import-Module MicrosoftPowerBIMgmt
    }
    
}


function CreatePowerBiWorkspace {
    <#
    .DESCRIPTION
    Creates worspace after check if it already exists
    
#>


    Param([Parameter(Mandatory = $true)][String]$workspace_name)

    ### ENVIRONMENT VARIABLES ============================================

    $workspaceName = $workspace_name

    ### ADD NEW WORKSPACE ================================================

    Write-Host "Checking if {0} exists" -f $workspaceName

    $workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization

    if ($workspace) {
        Write-Warning "The workspace named $workspaceName already exists"
    }
    else {
        Write-Host "Creating new workspace named $workspaceName"
        $workspace = New-PowerBIGroup -Name $workspaceName
    }

    
}


function AddWorkspaceAccessToUser {
    <#
    .DESCRIPTION
    This function adds the identified email user as admin of the workspace in power BI. It checks whether the use is already authorised.
    .PARAMETER <Workspace_Principal_type>
    This param must be 'user' for this case. Could be App, Group, User if extended
    .PARAMETER <Workspace_Access_type>
    Member, Admin, Contributor, Viewer
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


function AddPowerBiWorkSpaceToCapacity {
    <#
        .DESCRIPTION
        Adds the named workspace to to named capacity
        #>
        
    Param([Parameter(Mandatory = $true)]$workspace_name, $CapacityName)
        
    ### ENVIRONMENT VARIABLES ============================================
        
    $workspaceName = $workspace_name
        
    Write-Host "Checking $CapacityName exists"
        
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
}


function AddPowerBiWorkSpaceToCapacity {
    <#
            .DESCRIPTION
            Adds the named workspace to to named capacity
            #>
            
    Param([Parameter(Mandatory = $true)]$workspace_name, $CapacityName)
            
    ### ENVIRONMENT VARIABLES ============================================
            
    $workspaceName = $workspace_name
            
    Write-Host "Checking $CapacityName exists"
            
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
}

function PublishPbixFilesToWorkspaceRecursive {
    <#
    .DESCRIPTION
    Given a workspace name this function publishes all pbix file in the path parameter to that workspace. Path is search recursively for PBIX files.
    .PARAMETER <pbix_path>
    can be relative i.e. .\*.pbix
    
    #>
    
    Param([Parameter(Mandatory = $true)]$workspace_name, $pbix_path)
    
    
    ### ENVIRONMENT VARIABLES ============================================
    
    $workspaceName = $workspace_name 
    
    ### UPLOAD ALL PBIX FILES IN FOLDER ==================================
    
    # GET WORKSPACE ID
    Write-Host "Getting Workspace ID"
    $workspace = Get-PowerBIWorkspace -Name $workspaceName -Scope Organization
    $workspaceID = $workspace.Id
    $workspaceID
    
    # UPLOAD PBIX FILES
    $searchedFiles = Get-ChildItem -Path $pbix_path -Recurse
    foreach ($foundFile in $searchedFiles) {
        $directory = $foundFile.DirectoryName
        $file = $foundFile.Name
        $filePath = "$directory/$file"
        Write-Host "Publishing PBIX file to Power BI... Source folder: $filePath"
        $pbixFilePath = $filePath
        $import = New-PowerBIReport -Path $pbixFilePath -Workspace $workspace -ConflictAction CreateOrOverwrite
        $import | Select-Object
    }
}