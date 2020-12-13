param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aro-workshop-rg",        
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $appgwVnetName = "aro-landing-vnet",        
        [Parameter(Mandatory=$false)] [string] $appgwName = "aro-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aro-workshop-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "aro-appgw-deploy",        
        [Parameter(Mandatory=$false)] [string] $backendIPAddress = "181.0.0.4",
        [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>")

$templatesFolderPath = $baseFolderPath + "/Templates"

# Install APIM
# TBD

# Install AppGW
# backendIP should the Private IP of APIM
$networkNames = "-appgwName $appgwName -appgwVnetName $appgwVnetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName -backendIPAddress $backendIPAddress $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "-----------Post-Config------------"
