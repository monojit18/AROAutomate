param([Parameter(Mandatory=$true)]   [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $appgwName,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $subnetName,
        [Parameter(Mandatory=$true)] [string] $backendIPAddress)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-backendIpAddress1 $backendIPAddress

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-backendIpAddress1 $backendIPAddress