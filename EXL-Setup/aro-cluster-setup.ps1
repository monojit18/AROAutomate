param([Parameter(Mandatory=$true)]    [string] $mode, 
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $vNetName = "aro-workshop-vnet",        
        [Parameter(Mandatory=$false)] [string] $workerSubnetName = "aro-worker-subnet",
        [Parameter(Mandatory=$false)] [string] $masterSubnetName = "aro-master-subnet",
        [Parameter(Mandatory=$false)] [string] $clusterType = "Private",
        [Parameter(Mandatory=$false)] [string] $workerCount = 3,
        [Parameter(Mandatory=$false)] [string] $clientId = "afb29bb7-811b-4d4f-a4c1-3f808fd9cb9f",
        [Parameter(Mandatory=$true)]  [string] $clientSecret = "<client_secret>",
        [Parameter(Mandatory=$true)]  [string] $pullSecretPath = "/path/to/pull-secret.txt",
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>")

$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

if ($mode -eq "create")
{

    Write-Host "Creating Cluster... $clusterName"

    az aro create `
    --resource-group $resourceGroup `
    --vnet-resource-group $vnetResourceGroup `
    --location $location `
    --name $clusterName `
    --vnet $vNetName `
    --master-subnet $masterSubnetName `
    --worker-subnet $workerSubnetName `
    --apiserver-visibility $clusterType `
    --ingress-visibility $clusterType `
    --worker-count $workerCount `
    --client-id $clientId `
    --client-secret $clientSecret `
    --pull-secret @$pullSecretPath
    
}

Write-Host "-----------ARO Cluster Setup------------"