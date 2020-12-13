param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "arowkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aro-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aroSPName = "aro-workshop-sp",
        [Parameter(Mandatory=$false)] [string] $acrSPName = "aro-workshop-acr-sp",
        [Parameter(Mandatory=$false)] [string] $vnetName = "aro-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $vnetPrefix = "181.0.0.0/20",
        [Parameter(Mandatory=$false)] [string] $workerSubnetName = "aro-worker-subnet",
        [Parameter(Mandatory=$false)] [string] $workerSubNetPrefix = "181.0.0.0/21",
        [Parameter(Mandatory=$false)] [string] $masterSubnetName = "aro-master-subnet",
        [Parameter(Mandatory=$false)] [string] $masterSubNetPrefix = "181.0.8.0/24",        
        # [Parameter(Mandatory=$false)] [string] $appgwName = "aro-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "aro-network-deploy",
        [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "aro-acr-deploy",
        [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "aro-keyvault-deploy",        
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>",
        [Parameter(Mandatory=$true)]  [string] $objectId = "<objectId>",        
        [Parameter(Mandatory=$true)]  [string] $tenantId = "<tenantId>",
        [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>") # As per host machine

$aroSPRole = "Contributor"
$aroSPIdName = $clusterName + "-sp-id"
$aroSPSecretName = $clusterName + "-sp-secret"
$acrSPRole = "acrpush"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Templates"

$subscriptionCommand = "az account set -s $subscriptionId"
# $certSecretName = $appgwName + "-cert-secret"
# $certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

# Assuming Logged In

$networkNames = "-vnetName $vnetName -vnetPrefix $vnetPrefix -masterSubnetName $masterSubnetName -masterSubNetPrefix $masterSubNetPrefix -workerSubnetName $workerSubnetName -workerSubNetPrefix $workerSubNetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/$kvTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $kvTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"

# $certSecretName = $appgwName + "-cert-secret"
# $certPFXFilePath = $baseFolderPath + "/Certs/appgwcert.pfx"

# Assuming Logged In

# $loginCommand = "/Security/aro-master-login.ps1 -userName $masterClientId -password $masterClientSecret -subscriptionId $subscriptionId -tenantId $tenantId"
# $loginCommandPath = $baseFolderPath + $loginCommand

# try
# {
#     Invoke-Expression -Command $loginCommandPath    
# }
# catch
# {
#     Write-Host "Can not proceed further!!"
#     return;    
# }

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId
# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$rgRef)
{

   $rgRef = New-AzResourceGroup -Name $resourceGroup -Location $location
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

}

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

# Write-Host $certPFXFilePath
# $certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
# $certContents = [Convert]::ToBase64String($certBytes)
# $certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force
# Write-Host $certPFXFilePath

$aroSP = Get-AzADServicePrincipal -DisplayName $aroSPName
if (!$aroSP)
{
    $aroSP = New-AzADServicePrincipal -SkipAssignment -Role $aroSPRole `
    -DisplayName $aroSPName
    if (!$aroSP)
    {

        Write-Host "Error creating Service Principal for ARO"
        return;

    }

    Write-Host $aroSPName

    $aroSPObjectId = ConvertTo-SecureString -String $aroSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aroSPIdName `
    -SecretValue $aroSPObjectId
    Write-Host $aroSPIdName

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aroSPSecretName `
    -SecretValue $aroSP.Secret
    Write-Host $aroSPSecretName

}

$acrSP = Get-AzADServicePrincipal -DisplayName $acrSPName
if (!$acrSP)
{
 
    $acrSP = New-AzADServicePrincipal -SkipAssignment -Role $acrSPRole `
    -DisplayName $acrSPName
    if (!$acrSP)
    {

        Write-Host "Error creating Service Principal for ACR"
        return;

    }

    Write-Host $acrSPName

    $acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
    -SecretValue $acrSPObjectId

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
    -SecretValue $acrSP.Secret
    
}

Write-Host "-----------PreConfig------------"