param([Parameter(Mandatory=$true)]    [string]  $userName = "<user_name>",
        [Parameter(Mandatory=$true)]  [string]  $password = "<password>",
        [Parameter(Mandatory=$true)]  [string]  $subscriptionId = "<subscriptionId>",
        [Parameter(Mandatory=$true)]  [string]  $tenantId = "<tenantId>")

$securedPassword = ConvertTo-SecureString $password -AsPlainText -Force
$spCreds = New-Object -TypeName "System.Management.Automation.PSCredential" `
-ArgumentList $userName,$securedPassword
try
{
        Connect-AzAccount -Credential $spCreds -TenantId $tenantId `
        -ServicePrincipal -Subscription $subscriptionId `
        -ErrorAction Stop       
}
catch
{
        throw "Error Login with user - $userName"
}

$loginCommand = "az login --service-principal -u $userName -p $password --tenant $tenantId"
Invoke-Expression -Command $loginCommand
$LastExitCode
if (!$?)
{
        throw "Error Login with user - $userName"
}


