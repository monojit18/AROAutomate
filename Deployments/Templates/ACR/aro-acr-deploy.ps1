param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $acrName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/ACR/$deployFileName.json" `
-acrName $acrName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/ACR/$deployFileName.json" `
-acrName $acrName
