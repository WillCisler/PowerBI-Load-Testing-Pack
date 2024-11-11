$ImagePublisher = "MicrosoftWindowsDesktop" #"microsoft-dsv" #microsoft-ads
$ImageOffer = "Windows-10" #"dsvm-win-2019" #"windows-data-science-vm"
$ImageSKU = "win10-21h2-pro-g2" #"winserver-2019" #windows2016

$locName="uksouth"
Get-AzVMImagePublisher -Location $locName | Select PublisherName

$pubName=$ImagePublisher
Get-AzVMImageOffer -Location $locName -PublisherName $pubName | Select Offer

$offerName=$ImageOffer
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select Skus

$skuName=$ImageSKU
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Sku $skuName | Select Version


$version = "20.01.10"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version

#plan
#Get-AzVMImage -Location "westus" -PublisherName "microsoft-ads" -Offer "windows-data-science-vm" -Skus "windows2016" -Version "0.2.02"


#licence
Get-AzMarketplaceterms -Publisher "microsoft-ads" -Product "windows-data-science-vm" -Name "windows2016"

#$agreementTerms=Get-AzMarketplaceterms -PublisherName $pubName -Offer $offerName -Skus $skuName
$agreementTerms=Get-AzMarketplaceTerms  -Publisher $pubName -Product $offerName -Name $skuName



$agreementTerms=Get-AzMarketplaceterms -Publisher "microsoft-ads" -Product "windows-data-science-vm" -Name "windows2016"
Set-AzMarketplaceTerms -Publisher "microsoft-ads" -Product "windows-data-science-vm" -Name "windows2016" -Terms $agreementTerms -Accept


$agreementTerms=Get-AzMarketplaceterms -Publisher "microsoft-dsv" -Product "dsvm-win-2019" -Name "winserver-2019"

Set-AzMarketplaceTerms  -Publisher "microsoft-dsv" -Product "dsvm-win-2019" -Name "winserver-2019" -Accept

###############important
Set-AzMarketplaceTerms  -Publisher "microsoft-ads" -Product "windows-data-science-vm" -Name "windows2016" -Accept
#create
...

$vmConfig = New-AzVMConfig -VMName "myVM" -VMSize Standard_DS3_v2

# Set the Marketplace image
$offerName = "windows-data-science-vm"
$skuName = "windows2016"
$version = "20.01.10"
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version $version

# Set the Marketplace plan information, if needed
$publisherName = "microsoft-ads"
$productName = "windows-data-science-vm"
$planName = "windows2016"
$vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $publisherName -Product $productName -Name $planName

...

##############################
Get-AzMarketplaceTerms  -Publisher "microsoft-ads" -Product "windows-data-science-vm" -Name "windows2016" -OfferType 'virtualmachine' | Set-AzMarketplaceTerms -Accept

...

$vmConfig = New-AzVMConfig -VMName "myVM" -VMSize Standard_D1

# Set the Marketplace image
$offerName = "windows-data-science-vm"
$skuName = "windows2016"
$version = "19.01.14"
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version $version

# Set the Marketplace plan information, if needed
$publisherName = "microsoft-ads"
$productName = "windows-data-science-vm"
$planName = "windows2016"
$vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $publisherName -Product $productName -Name $planName

...