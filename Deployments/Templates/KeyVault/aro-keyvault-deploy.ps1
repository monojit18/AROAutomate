param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $keyVaultName,        
        [Parameter(Mandatory=$true)] [string] $objectId)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/KeyVault/$deployFileName.json" `
-keyVaultName $keyVaultName -objectId $objectId

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/KeyVault/$deployFileName.json" `
-keyVaultName $keyVaultName -objectId $objectId