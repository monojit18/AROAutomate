param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $vnetRG,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $privateEndpointName,
        [Parameter(Mandatory=$true)] [string] $privateEndpointConnectionName,        
        [Parameter(Mandatory=$true)] [string] $pepResourceType,        
        [Parameter(Mandatory=$true)] [string] $pepResourceName,
        [Parameter(Mandatory=$true)] [string] $vnetName,        
        [Parameter(Mandatory=$true)] [string] $subnetName,
        [Parameter(Mandatory=$true)] [string] $subResourceId)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-vnetRG $vnetRG `
-privateEndpointName $privateEndpointName `
-privateEndpointConnectionName $privateEndpointConnectionName `
-pepResourceType $pepResourceType `
-pepResourceName $pepResourceName `
-vnetName $vnetName -subnetName $subnetName `
-subResourceId $subResourceId

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-vnetRG $vnetRG `
-privateEndpointName $privateEndpointName `
-privateEndpointConnectionName $privateEndpointConnectionName `
-pepResourceType $pepResourceType `
-pepResourceName $pepResourceName `
-vnetName $vnetName -subnetName $subnetName `
-subResourceId $subResourceId