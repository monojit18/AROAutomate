param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "aro-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aro-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "arowkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aro-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $vnetName = "aro-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $vnetIPAddess = "181.0.0.0/20",
        [Parameter(Mandatory=$false)] [string] $workerSubnetName = "aro-worker-subnet",
        [Parameter(Mandatory=$false)] [string] $workerSubnetIPAddress = "181.0.0.0/21",
        [Parameter(Mandatory=$false)] [string] $masterSubnetName = "aro-master-subnet",
        [Parameter(Mandatory=$false)] [string] $masterSubnetIPAddress = "181.0.8.0/24",
        [Parameter(Mandatory=$false)] [string] $aroSPName = "aro-workshop-sp",
        [Parameter(Mandatory=$false)] [string] $clusterType = "Private",
        [Parameter(Mandatory=$false)] [string] $workerCount = 3,
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>")

$aroSPRole = "Contributor"
$aroSPIdName = $clusterName + "-sp-id"
$aroSPSecretName = $clusterName + "-sp-secret"

$subscriptionCommand = "az account set -s $subscriptionId"
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

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$aroSP = Get-AzADServicePrincipal -DisplayName $aroSPName
if (!$aroSP)
{
        $aroSP = New-AzADServicePrincipal -SkipAssignment -Role $aroSPRole `
        -DisplayName $aroSPName
        if (!$aroSP)
        {

                Write-Host "Error creating Service Principal for AKS"
                return;

        }

        $aroSPObjectId = ConvertTo-SecureString -String $aroSP.ApplicationId `
        -AsPlainText -Force

        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aroSPIdName `
        -SecretValue $aroSPObjectId

        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aroSPSecretName `
        -SecretValue $aroSP.Secret

}

$vnet = Get-AzVirtualNetwork -Name $vnetName `
-ResourceGroupName $vnetResourceGroup
if (!$vnet)
{

    # Create VNET
    $vnetCommand = "az network vnet create --resource-group $vnetResourceGroup --name $vnetName --address-prefixes $vnetIPAddress"
    Invoke-Expression -Command $vnetCommand

}

$workerSubnet = Get-AzVirtualNetworkSubnetConfig -Name $workerSubnetName `
-VirtualNetwork $vnet
if (!$workerSubnet)
{

    # Create Worker SubNET
    $workerSubnetCommand = "az network vnet subnet create --name  $workerSubnetName --resource-group $vnetResourceGroup --vnet-name $vnetName --address-prefixes $workerSubnetIPAddress --service-endpoints Microsoft.ContainerRegistry"
    Invoke-Expression -Command $workerSubnetCommand

}

$masterSubnet = Get-AzVirtualNetworkSubnetConfig -Name $masterSubnetName `
-VirtualNetwork $vnet
if (!$masterSubnet)
{

    # Create Master SubNET
    $masterSubnetCommand = "az network vnet subnet create --name  $masterSubnetName --resource-group $vnetResourceGroup --vnet-name $vnetName --address-prefixes $masterSubnetIPAddress --service-endpoints Microsoft.ContainerRegistry"
    Invoke-Expression -Command $masterSubnetCommand

    # Disable PrivateLink for Master Subnet
    $disablePrivateLinkCommand = "az network vnet subnet update --name $masterSubnetName --resource-group $vnetResourceGroup --vnet-name $vnetName --disable-private-link-service-network-policies true"
    Invoke-Expression -Command $disablePrivateLinkCommand

}

Write-Host "-----------PreConfig------------"