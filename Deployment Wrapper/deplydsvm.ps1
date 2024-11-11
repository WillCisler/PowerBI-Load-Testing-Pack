function DeployLoadTestingVm {

<#
    This Script Builds all the neccesary componet to run a Data Science Virtual machine and connect to it via RDF

    Some notes tbd

    Here is a PowerShell script that creates a new Azure virtual machine using the Windows 10 image:
#>
param (
    [string]$resourceGroup = "pbiLoadTesting",
    [string]$location = "uksouth",
    [string]$vmName = "myWin10", #"MyDSVM"
    [string]$vmSize = "Standard_DS3_v2",
    [string]$offerName = "Windows-10", #"windows-data-science-vm",
    [string]$skuName = "win10-21h2-pro-g2", #"windows2016",
    [string]$version = "latest", #"20.01.10",
    [string]$publisherName = "MicrosoftWindowsDesktop", ##"microsoft-ads",
    [string]$productName = "Windows-10", #"windows-data-science-vm",
    [string]$planName = "windows2016",
    [Parameter(Mandatory=$true)]
    [string]$adminEmail
)


Start-Sleep -Seconds 2.0

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine. Note these down as you will need them to login to the VM later"

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

<#
Plan not needed for Win10 machine but required for windows-data-science-vm
#>
if ($offerName == 'windows-data-science-vm') {
  $vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $publisherName -Product $productName -Name $planName
}


#NIC
Write-Host("Set NIC for VM")
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Create a virtual machine
Write-Host(" Creating virtual machine")
$newVM = New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# This code is meant to print the link to new VM for ease of use
Connect-AzureAD
$tenantDetail = Get-AzureADTenantDetail
$subscription = Get-AzSubscription
#write-host "https://portal.azure.com/#{0}/resource/subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.Compute/virtualMachines/{3}/overview" -f $tenantDetail.VerifiedDomain $subscription.Id $resourceGroup $vmName

write-host "https://portal.azure.com/#$($tenantDetail.VerifiedDomain.Name)/resource/subscriptions/$($subscription.Id)/resourceGroups/$($resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($vmName)/overview"


#https://portal.azure.com/#@MngEnv789898.onmicrosoft.com/resource/subscriptions/893f185b-4f2d-41e7-89c1-aa4ba4475e8c/resourceGroups/pbiLoadTestingC/providers/Microsoft.Compute/virtualMachines/myWin10/overview

}