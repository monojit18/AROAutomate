param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>")

$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$removeCommand = "az aro delete -n $clusterName -g $resourceGroup -y"
Invoke-Expression -Command $removeCommand

Write-Host "-----------ARO Cluster Remove------------"