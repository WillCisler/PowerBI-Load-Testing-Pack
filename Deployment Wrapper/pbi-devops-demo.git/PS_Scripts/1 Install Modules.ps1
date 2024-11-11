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