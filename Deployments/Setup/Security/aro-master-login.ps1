param([Parameter(Mandatory=$true)]    [string]  $userName = "<userName>",
        [Parameter(Mandatory=$true)]  [string]  $password = "<password>",
        [Parameter(Mandatory=$true)]  [string]  $apiServer = "<apiServerUrl>",
        [Parameter(Mandatory=$true)]  [string]  $adminUserName = "<adminUserName>",
        [Parameter(Mandatory=$true)]  [string]  $adminSecret = "<adminSecret>",
        [Parameter(Mandatory=$true)]  [string]  $projectName = "<projectName>",
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

$ocLoginCommand = "oc login $apiServer -u $adminUserName -p $adminSecret"
Invoke-Expression -Command $ocLoginCommand
$LastExitCode
if (!$?)
{
        throw "Error Login through OC CLI with user - $adminUserName"
}

$ocProjectCommand = "oc project $projectName"
Invoke-Expression -Command $ocProjectCommand
$LastExitCode
if (!$?)
{
        throw "Error switching to project - $projectName"
}
