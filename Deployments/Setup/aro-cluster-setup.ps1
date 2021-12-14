param([Parameter(Mandatory=$true)]    [string] $mode, 
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aro-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $vnetName = "aro-workshop-vnet",        
        [Parameter(Mandatory=$false)] [string] $workerSubnetName = "aro-worker-subnet",
        [Parameter(Mandatory=$false)] [string] $masterSubnetName = "aro-master-subnet",
        [Parameter(Mandatory=$false)] [string] $clusterType = "Private",
        [Parameter(Mandatory=$false)] [Int16]  $workerCount = 3,        
        [Parameter(Mandatory=$false)] [string] $pullSecretPath = "/Users/monojitd/Materials/Projects/Quick-Helpers/pull-secret.txt",
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>")


$aroSPIdName = $clusterName + "-sp-id"
$aroSPSecretName = $clusterName + "-sp-secret"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$clientId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aroSPIdName
if (!$clientId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$clientSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aroSPSecretName
if (!$clientSecret)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

if ($mode -eq "create")
{

    Write-Host "Creating Cluster... $clusterName"

    if ($clusterType -eq "Private")
    {
        az aro create `
        --resource-group $resourceGroup `
        --vnet-resource-group $vnetResourceGroup `
        --location $location `
        --name $clusterName `
        --vnet $vnetName `
        --master-subnet $masterSubnetName `
        --worker-subnet $workerSubnetName `
        --apiserver-visibility Private `
        --ingress-visibility Private `
        --worker-count $workerCount `
        --client-id $clientId.SecretValueText `
        --client-secret $clientSecret.SecretValueText `
        --pull-secret @$pullSecretPath        

    }
    elseif ($clusterType -eq "Public")
    {
        az aro create `
        --resource-group $resourceGroup `
        --vnet-resource-group $vnetResourceGroup `
        --location $location `
        --name $clusterName `
        --vnet $vnetName `
        --master-subnet $masterSubnetName `
        --worker-subnet $workerSubnetName `
        --apiserver-visibility Public `
        --ingress-visibility Public `
        --worker-count $workerCount `
        --client-id $clientId.SecretValueText `
        --client-secret $clientSecret.SecretValueText `
        --pull-secret @$pullSecretPath

    }

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Creating ARO Cluster - $clusterName"
        return;
    
    }

}
elseif ($mode -eq "update")
{
    
    az aro update --name $clusterName `
    --resource-group $resourceGroup `
    --subscription $subscriptionId    

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating ARO Cluster - $clusterName"
        return;
    
    }

}

Write-Host "-----------ARO Cluster Setup------------"