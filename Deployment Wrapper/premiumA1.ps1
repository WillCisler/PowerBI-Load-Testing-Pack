<#
    This Script Builds then pauses an Embedded Power BI SKU

    Some notes tbd
#>
param (
    [string]$resourceGroup = "rg-pbi-premium-for-load-testing",
    [string]$location = "uksouth",
    [string]$capacityName = "capacityforloadtesting",
    [string]$pbiSKU = "A1",
    [Parameter(Mandatory=$true)]
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
#Resume-AzPowerBIEmbeddedCapacity -Name $capacityName -ResourceGroupName $resourceGroup -PassThru
#Test-AzPowerBIEmbeddedCapacity -Name $capacityName
#Remove-AzPowerBIEmbeddedCapacity -Name $capacityName -ResourceGroupName $resourceGroup

