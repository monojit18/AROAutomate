param([Parameter(Mandatory=$true)] [string] $resourceGroup = "aro-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $vnetResourceGroup = "aro-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $location = "eastus",
      [Parameter(Mandatory=$true)] [string] $clusterName = "aro-workshop-cluster",
      [Parameter(Mandatory=$true)] [string] $acrName = "arowkshpacr",
      [Parameter(Mandatory=$true)] [string] $keyVaultName = "aro-workshop-kv",
      [Parameter(Mandatory=$true)] [string] $aroSPName = "aro-workshop-sp",
      [Parameter(Mandatory=$true)] [string] $acrSPName = "aro-workshop-acr-sp",
      [Parameter(Mandatory=$true)] [string] $vnetName = "aro-workshop-vnet",
      [Parameter(Mandatory=$true)] [string] $vnetPrefix = "181.0.0.0/20",
      [Parameter(Mandatory=$true)] [string] $workerSubnetName = "aro-worker-subnet",
      [Parameter(Mandatory=$true)] [string] $workerSubNetPrefix = "181.0.0.0/21",
      [Parameter(Mandatory=$true)] [string] $masterSubnetName = "aro-master-subnet",
      [Parameter(Mandatory=$true)] [string] $masterSubNetPrefix = "181.0.8.0/24",        
      # [Parameter(Mandatory=$true)] [string] $appgwName = "aro-workshop-appgw",
      [Parameter(Mandatory=$true)] [string] $networkTemplateFileName = "aro-network-deploy",
      [Parameter(Mandatory=$true)] [string] $acrTemplateFileName = "aro-acr-deploy",
      [Parameter(Mandatory=$true)] [string] $kvTemplateFileName = "aro-keyvault-deploy",
      [Parameter(Mandatory=$true)] [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$true)] [string] $objectId = "<objectId>",
      [Parameter(Mandatory=$true)] [string] $tenantId = "<tenantId>",
      [Parameter(Mandatory=$true)] [string] $baseFolderPath = "<baseFolderPath>") # As per host machine

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

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
if (!$subscription)
{
    Write-Host "Error fetching Subscription information"
    return;
}

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

$aroVnet = Get-AzVirtualNetwork -Name $vnetName `
-ResourceGroupName $resourceGroup
$networkDeployPath = $templatesFolderPath + $networkDeployCommand
if (!$aroVnet)
{
    
    Invoke-Expression -Command $networkDeployPath    

}

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
    $aroSP = New-AzADServicePrincipal -SkipAssignment `
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

    New-AzRoleAssignment -RoleDefinitionName $aroSPRole  `
    -ApplicationId $aroSP.ApplicationId -Scope $subscription.Id

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if (!$acrInfo)
{

    Write-Host "Error fetching ACR information"
    return;

}

$acrSP = Get-AzADServicePrincipal -DisplayName $acrSPName
if (!$acrSP)
{

    $acrSP = New-AzADServicePrincipal -SkipAssignment `
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

    New-AzRoleAssignment -RoleDefinitionName $acrSPRole  `
    -ApplicationId $acrSP.ApplicationId -Scope $subscription.Id
    
}

New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
-RoleDefinitionName $acrSPRole -Scope $acrInfo.Id

Write-Host "----------------PreConfig----------------"