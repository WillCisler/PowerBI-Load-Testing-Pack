# Set variables for resource group and location
$rgName = "RG-pbiLoadTest"
$location = "uksouth"

# Set variables for virtual machine
$vmName = "VM-pbiLoadTest"
$vmSize = "Standard_DS3_v2"
$imagePublisher = "microsoft-ads"
$imageOffer = "windows-data-science-vm"
$imageSKU = "windows2016"
$adminUsername = "LocalAdminUser"
$adminPassword = "myPassword123!"
# Create a new resource group
$rg = New-AzResourceGroup -Name $rgName -Location $location
#create creds
$creds = (New-Object System.Management.Automation.PSCredential ($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force)))


# Create a new virtual machine configuration
#$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Specify the image for the virtual machine
#$image = Get-AzVMImagePublisher -Location $location -PublisherName $imagePublisher | `
#        Get-AzVMImageOffer -Offer $imageOffer | `
#        Get-AzVMImageSku -Skus $imageSKU | `
#        Select -ExpandProperty Version | `
#        Select -First 1

$getpublisher = Get-AzVMImagePublisher -Location $location | Where-Object PublisherName -eq $imagePublisher
$getOffer = Get-AzVMImageOffer -PublisherName $getpublisher.PublisherName -Location $location | Where-Object Offer -eq $imageOffer
$getSku = Get-AzVMImageSku -Location $location -Offer $getOffer.Offer -PublisherName $getpublisher.PublisherName | Select -First 1

$image2 = $getSku
$image2

#$image = Get-AzVMImagePublisher -Location $location -PublisherName $imagePublisher | Get-AzVMImageOffer -Offer $imageOffer | Get-AzVMImageSku -Skus $imageSKU | Select -ExpandProperty Version | Select -First 1


# Add the image to the virtual machine configuration


#initiate vm setting
$VMSettings = New-AzVMConfig -VMName $vmName -VMSize $vmSize
#get image
$image =Get-AzVMImage `
    -PublisherName $imagePublisher `
    -Offer $imageOffer `
    -Skus $imageSku `
    -Location $location | Select-Object -Last 1
#Set image in settings
$image | Set-AzVmSourceImage -VM $VMSettings
# Configure the operating system. 
Set-AzVMOperatingSystem -VM $VMSettings `
   -Windows `
   -ComputerName "MyVm101" `
   -Credential $creds

   # Configure the Disks
Set-AzVMOSDisk -VM $vmSettings `
  -Name "MyVM-os" -Windows `
  -DiskSizeInGB 80 `
  -CreateOption FromImage
# - Create the network interface
$NetRG = Get-AzResourceGroup "NetworkResourceGroup"
$DemoNet = $NetRG | Get-AzVirtualNetwork -Name "DemoNetwork"
$Sub = $DemoNet.Subnets[0]
$NIC = $rg | New-AzNetworkInterface -Name "MyVM-Nic" -SubnetId $Sub.Id
# Add network to the VM
Add-AzVMNetworkInterface -VM $VMSettings -Id $NIC.Id
# Build the VM in the resource group
$rg | New-AzVm -VM $VMSettingsget


New-AzVm `
    -ResourceGroupName $rgName `
    -Name $vmName `
    -Location $location `
    -Image $image.Skus `
    -size $vmSize `
    -PublicIpAddressName myPubIP `
    -OpenPorts 80 `
    -Credential $creds



$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux false -ComputerName $vmName -Credential $creds -ProvisionVMAgent -EnableAutoUpdate | Set-AzVMSourceImage -Id $image.Id



# Set the virtual machine resources
$vmConfig = Set-AzVMProcessorCount -VM $vmConfig -Count 8
$vmConfig = Set-AzVMMemory -VM $vmConfig -MemoryInGB 64

# Create the virtual machine
New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
#####

$rgName = "RG-pbiLoadTest"
$location = "uksouth"

# Set variables for virtual machine
$vmName = "VM-pbiLoadTest"
$vmSize = "Standard_DS3_v2"

$adminUsername = "LocalAdminUser"
$adminPassword = "myPassword123!"



#General VARS
$ResourceGroupName = "pbiLoadTesting"
$LocationName = "uksouth"
#VM VARS
$VMLocalAdminUser = "LocalAdminUser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "myPassword123!" -AsPlainText -Force
$ComputerName = "MyVM"
$VMName = "MyVM"
$VMSize = "Standard_DS3_v2"
$ImagePublisher = "microsoft-ads" #"microsoft-dsv" #microsoft-ads
$ImageOffer = "windows-data-science-vm" #"dsvm-win-2019" #"windows-data-science-vm"
$ImageSKU = "windows2016" #"winserver-2019" #windows2016
$version = "20.01.10"
#PLAN VARS for DSVM they map to Publisher, offer and sku
#$publisherName = "microsoft-ads"
#$productName = "windows-data-science-vm"
#$planName = "windows2016"
## NET VARS
$NetworkName = "MyNet"
$NICName = "MyNIC"
$SubnetName = "MySubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"
#CreateRG
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $LocationName
#Create Network
$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id
#Creds
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#VM Config
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSKU -Version $version
$VirtualMachine = Set-AzVMPlan -VM $VirtualMachine -Name $ImageOffer -Product $ImageOffer -Publisher $ImagePublisher
#Create VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose


Get-AzVMImage -Location $LocationName -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $imageSKU -Version latest

$getpublisher = Get-AzVMImagePublisher -Location $LocationName | Where-Object PublisherName -eq $ImagePublisher
$getOffer = Get-AzVMImageOffer -PublisherName $getpublisher.PublisherName -Location $LocationName | Where-Object Offer -eq $imageOffer
$getSku = Get-AzVMImageSku -Location $LocationName -Offer $getOffer.Offer -PublisherName $getpublisher.PublisherName | Select -First 1
$image2 = $getSku
$image2


$agreementTerms=Get-AzMarketplaceterms -Publisher "microsoft-dsv" -Product "dsvm-win-2019" -Name "windows-2019"

Set-AzMarketplaceTerms -Publisher "microsoft-dsv" -Product "dsvm-win-2019" -Name "windows-2019" -Terms $agreementTerms -Accept