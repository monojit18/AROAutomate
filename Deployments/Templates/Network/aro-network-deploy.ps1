param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $vnetPrefix,
        [Parameter(Mandatory=$true)] [string] $workerSubnetName,
        [Parameter(Mandatory=$true)] [string] $workerSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $masterSubnetName,
        [Parameter(Mandatory=$true)] [string] $masterSubNetPrefix)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-vnetName $vnetName -vnetPrefix $vnetPrefix `
-workerSubnetName $workerSubnetName -workerSubNetPrefix $workerSubNetPrefix `
-masterSubnetName $masterSubnetName -masterSubNetPrefix $masterSubNetPrefix

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-vnetName $vnetName -vnetPrefix $vnetPrefix `
-workerSubnetName $workerSubnetName -workerSubNetPrefix $workerSubNetPrefix `
-masterSubnetName $masterSubnetName -masterSubNetPrefix $masterSubNetPrefix