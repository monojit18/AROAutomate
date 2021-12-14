param([Parameter(Mandatory=$true)][string] $userName)

Disconnect-AzAccount -Username $userName

$logoutCommand = "az logout --username $userName"
Invoke-Expression -Command $logoutCommand


