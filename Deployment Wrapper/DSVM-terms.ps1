$title   = 'Accepting terms'
$msg     = 'Do you accept the licence terms for the Azure marketplace DSVM?'
$options = '&Yes', '&No'
$default = 1  # 0=Yes, 1=No


$response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
    if ($response -eq 0) { `
        Get-AzMarketplaceTerms  `
            -Publisher "microsoft-ads" `
            -Product "windows-data-science-vm" `
            -Name "windows2016" -OfferType 'virtualmachine' | `
            Set-AzMarketplaceTerms -Accept
    }



