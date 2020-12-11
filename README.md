# 				ARO - Anatomy of Deployment

## Prelude

ARO aka *Azure RedHat OpenShift* is a managed Service on Azure - engineered jointly by Microsoft and RedHat engineers. OpenShift being a managed service around vanilla Kubernetes (K8s); ARO brings in the flavour of Azure - 

- **Infrastructure Management** - Nodes, Managed Disks, VNETs, Subnets, DNS Zones, LoadBalancers etc.

- **Authentication/Authorization**  - AAD integration, RBAC thru AAD

- **Monitoring** - Integration with Azure Monitor (Preview)

- **Storage Management** - Storage Classes (azureFile, azureDisk)

- **Security** - Private Endpoint connectivity with other Azure services like *Azure Storage, Azure KeyVault, Azure SQL, CosmosDB* etc.

  ......and More

Creation of ARO cluster is quite different from traditional PaaS services deployment. It is not only the cluster that one should be considering; there are other surrounding services (*read Infrastructure services*) that also should be taken into account, while planning for ARO cluster.

Actually these services around ARO cluster are more important and critical to manage for the proper functioning of the cluster; and also following all the best practices.

Let us divide the entire set of activities into 3 broad categories -

- **Day-0**: Planning Phase
- **Day-1**: Execution and Hardening Phase
- **Day-2**: Deployment Phase

## Day-0 Activities

### Plan User/Group management

This is to ensure a proper RBAC is implemented providing restricted access to various components within the ARO cluster.

- At least 3 Primary roles to be considered - *Cluster Admi*n, *Architects*/*Managers* and *Developers*. Based on requirement more cna be thought of
- These groups would be added as OpenShift group objects with clear segregation of responsibilities
  - All access to *Cluster Admins*
  - Less Access to *Architects* but enough to manage the entire cluster operation - Deployment, Monitoring, Troubleshooting, Security etc.
  - Least access to *Developers* - Primarily to allow them to deploy using Code changes and CI/CD; but provide the amount of access to perform basic application management like *Pods, Deployments, Services* etc.
- Actual *Role Assignment* and *Role Bindings* would happen on **Day-1**

### Plan Network topology

- **Hub-n-Spoke Or Dedicated**

  - Preferred is *Hub-n-Spoke* as it makes entire topology flexible

  - In both the cases decide on the list of VNETs and Subnets to used (*Existing* or *New*). At the minimum following is the list that are needed -

    **VNETs** - 

    - **Hub VNET** - Contains Subnets that are used across multiple resources, clusters or services e.g.

      - **Application Gateway Subnet** - **/27** should be a good choice for Dev/UAT and Prod both
        - Select **Standard_V2** at least and **WAF_V2** if WAF service is needed as well
        - Used as external LoadBalancer, performs SSL Offloading (*optional*), maintains a backend pool of Private IPs - e.g. Private IP of Nginx Ingress controller. This way communication remains secure yet flexible
      - **Bastion Host Subnet** - **/29** should be a good choice for Dev/UAT and Prod both
        - Primarily used for connecting to Private resources within the Architecture e.g. Private ARO cluster
        - Should have all necessary s/w to be installed viz. 
          - *Docker*
          - *Kubectl*
          - *Azure CLI*
          - *Helm*
          - *Git, Any GitHub Client*
          - *PowerShell Core*
          - *VS Code IDE and associated plugins - azure, git, PowerShell*
      - **Firewall Subnet** *(Optional) -* https://docs.microsoft.com/en-us/azure/firewall/features 
      - **Gateway Subnet** (*Optional*) -  For On-Prem Connectivity over *site-to-site* or *point-to-site*

    - **ARO+ VNET** - **/20** for *Dev* and /**18** for *Prod* at least

      - **ARO subnet** - A completely dedicated Subnet for ARO cluster. No other resources to be planned on this. 

        **<u>/21, 22</u>** for Dev/UAT and **<u>/18, /20</u>** for Prod id safe to choose. *If Address space is an issue then Kubenet*. This should be a dedicated subnet for ARO cluster.

        The question that should debated at this stage are -

        - How many micro-services approximately to be deployed (*now* and *in future*)
    
        - What would the minimum and maximum no. of replicas for each
    
        - How much *CPU* and *Memory* that each micro-services could consume approximately
    
        - And based on all these –
      - What is Size of each *Node* (VM) i.e how many *Cores of CPU* and how much *GB of Runtime Memory*
          - how many *Nodes* (VMs) that the cluster could expect (*initially and when scaled up?*) – basically *minimum* and *maximum* no. of such *Nodes*
      
        - Finally *maximum* number of pods or app replicas you want in each *Node* – Ideally whatever be the size of the *Node*, this value should not go beyond 40-50; not an hard and fast rule but with standard VM sizes like 8 Core 16 GB, 40-50 *Pods* per *Node* is good enough Based on all these info, let us try to define a formulae to decide what would be the address space of VNET and Subnet for ARO.

          Let us assume,

          **Np** = Max. Number of Pods in each Node (Ideally should not be more ethan 40-50)

          **Nd** = Max. Number of Nodes possible (approx.)

          Then the total no. of addresses that you would need in ARO Subnet = ***(Np \* (Nd + 1) + Np)\***

          *+1 for reserved IP by system for each Node*

          *+Np for additional IPs you might need while Upgrade* – normally K8s system will pull down one Node at a time, transfer all workloads to another Node and then upgrade the previous Node

          It is advisable to keep some more in buffer based on workloads and other unforeseen situations

          What we have seen, for high end workloads, ideally for a *DEV-UAT* cluster, we should go with **/21 or /22** which means around 2k or 1k *Nodes*.

          *PROD* cluster should have a bit more like **/18 or /20** which means around 16k or 4k *Nodes*

        - Please note that for ARO cluster - 

          - Minimum 3 Master Nodes and 3 Worker Nodes are needed
      - Master Nodes are to sized at minimum Standard D8s v3 *(8 vcpus, 32 GiB memory)*
        
          - Worker Nodes are sized at minimum Standard D4s v3 *(4 vcpus, 16 GiB memory)*
    
    
    
    - **APIM subnet** (*Optional*) - One dedicated subnet for APIM. Two options are there - External VNET or Internal VNET.
      
      - *Same VNET or Separate VNET*? If one APIM across entire org then should be in a separate VNET and then peering with ARO VNET
        
      - *Address Space* - **/29** is enough for both DEV and PROD
        
        
      
  
  - **Integration Services VNET** - Provide Private endpoint for these all integration services peered with *ARO VNET* viz.
  
    - *Azure Container Registry aka ACR*
  
    - *Azure KeyVault*
  
    - *Storage*
  
    - *Azure SQL DB*
  
    - *Azure Redis Cache*
  
    - *Cosmos DB*
  
    - *Azure Service Bus*
  
    
  
  - **DevOps VNET** - *Self-hosted* DevOps agents - *Linux* or *Windows*; peered with *ARO VNET*
  
  
  
  - **NSGs to be decided Upfront**
    - Decide basic NSGs for all the subnets
    - Some important *Inbound* rules to be followed -
      - App G/W allows communication only from Azure Front door
      - APIM should accept traffic only from App G/W
      - ARO subnet should accept traffic only from APIM and/or On-Prem VNET gateway
    - Some important *Outbound* rules to be followed -
      - ARO Subnet outbound would always use the public *Standard LoadBalancer* created during Cluster creation process. To change that behaviour - add appripriate outbound rules and anyone of the following
        - Nat Gateway associated with ARO subnet
        - UDR through a Firewall Subnet
        - Forcing communication directly through web corporate proxy - this needs some amount scripting. Setting *http_proxy* or *https_proxy* can be deployed as a *Daemonset* on every ARO cluster node and force Nodes to send raffic through proxy

### Plan Communication to Azure Services

- **Private/Service Endpoints**

  ​	Plan to use  for *Private Endpoints* (Or atleast *Service Endpoints*) wherever possible for communiction with Azure resources 	like Storage, SQL, CosmosDB etc. This makes communication secure and fast

  

- **Service Principal for ARO cluster**

  - This is used by ARO runtime and if not provided creates a new one everytime a cluster is created
  - To avoid multiple unused, dangling Service Principals, recommendation is to create one and assign it to the cluster during creation time; also an be used across multiple clusters
  - Actual creation would happen on **Day-1**

### Plan DevOps setup

- Self Hosted agent - This ideally should be Ubuntu machine with at least 2 Core 8 GB spec (*Or Windows machine with similar configuration*)
- Same agent machine can be used both as *Build Agent* and *Deployment Agent*
- The VNET (*as described above*) should peered with ARO VNET
- ACR/KeyVault VNETs should be peered with DevOps VNET to make sure that CI/CD pipeline can access ACR images and KeyVault keys during the pipeline run

### Plan ACR setup

- Ideally two ACRs - one for DEV and one for PROD
- Private Endpoint support
- DevOps VNET should be able to access the ACR Subnet
- No Admin access enabled; Service principal to be used for accessing it from within the cluster as well as DevOps pipeline(s)

### Plan KeyVault setup

- Ideally One KeyVault - Managing the keys from different apps and environments with varying access

- Private Endpoint support

- DevOps VNET should be able to access the KeyVault Subnet. During CI/CD process all keys are downloaded from *KeyVault* and mapped to Application variables

  

## Day-1 Activities

### Execution and Hardening Phase

- ### **Referene** - 
  - Github repo link containing files needed to an ARO setup - https://github.com/monojit18/AROAutomate.git
  - Azure CLI approach is described here; but a more automated approach like *Terraform* Or *ARM Template* is preferred

- ### Prerequisites -

  - Select a suitable machine for initial setting up of the cluster - *Windows* or *Linux*. Refer to the Bastion Host setup described above in *Day-0* section
  - Private clusters would block all ARO API server access over public network; hence both CLI as well as Web Console would be blocked to access, view, manage cluster resources. If the plan is to create a *Private Cluster* then a designated machine is imperative for day-to-day operation of the cluster
  - Installation of Tools/Softwares
    - **Docker** - 
      - Windows - https://docs.docker.com/docker-for-windows/install/
      - Linux - https://runnable.com/docker/install-docker-on-linux
    - **Kubectl** - 
      - Windows - https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-with-curl-on-windows
      - Linux - https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
    - **Azure CLI** -
      - Windows - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli
      - Linux - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt#install
    - **Helm** -
      - Windows and Linux - https://helm.sh/docs/intro/install/
    - **Git** - 
      - Windows - https://git-scm.com/download/win
      - Linux - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
    - **GitHub Desktop** (*Windows only*) -
      - Windows - https://desktop.github.com/
    - **PowerShell Core** -
      - Windows and Linux - 
        - https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1
    - **VS Code IDE** -
      - Windows - https://code.visualstudio.com/

- **Login to the Azure account**

  ```bash
  az login
  ```

- **Set appropriate Account  (*for multiple subscriptions*)**

  ```bash
  az account set -s <subscription_id>
  ```

  

- **Register various Providers with Azure CLI**

  ```bash
  az provider register -n Microsoft.RedHatOpenShift --wait
  az provider register -n Microsoft.Compute --wait
  az provider register -n Microsoft.Storage --wait
  ```

  

- **Run the following command to install the ARO extension for Azure CLI**

  ```bash
  az extension add -n aro --index https://az.aroapp.io/stable
  ```

  

- **If you already have the extension installed, you can update by running the following command**

  ```bash
  az extension update -n aro --index https://az.aroapp.io/stable
  ```

  

- **Get a Red Hat pull secret (*Optional*)**

  - This is needed for accessing the in-built template and repositories tat comes as a bundle with OpenShift runtime
  - This would help installing most common services like various Databases, Web Servers, Test Frameworks etc. on the ARO cluster easily through certified, secured images provided by OpenShift
  - This is *Optional* but <u>*Recommended*</u>

  ```bash
  Register or Login at - https://cloud.redhat.com/openshift/install/azure/aro-provisioned
  ```

  

- **Define few CLI variables; this would facilitate the running of subsequent commands**

  ```bash
  $resourceGroup = "<place_holder>"
  $vnetResourceGroup = "<place_holder>"
  $vnetName = "<place_holder>"
  $vnetIPAddress = "<place_holder>"
  $workerSubnetName = "<place_holder>"
  $workerSubnetIPAddress = "<place_holder>"
  $masterSubnetName = "<place_holder>"
  $masterSubnetIPAddress = "<place_holder>"
  $servicePrincipalName = "<place_holder>"
  $location = "<place_holder>"
  $clusterName = "<place_holder>"
  $workerCount = 4 # change accordingly <num>
  $clusterType = "Public" # Public/Private
  ```

  

- **Create a virtual network referred as *ARO+ VNET* in the above *Day-0* section**

  ```bash
  az network vnet create \
  --resource-group $vnetResourceGroup \
  --name $vnetName \
  --address-prefixes $vnetIPAddress
  ```

  

- **Add an empty subnet for the worker nodes**

  ```bash
  az network vnet subnet create \
  --name  $workerSubnetName \
  --resource-group $vnetResourceGroup \
  --vnet-name $vnetName \
  --address-prefixes $workerSubnetIPAddress \
  --service-endpoints Microsoft.ContainerRegistry
  ```

  

- **Add an empty subnet for the master nodes**

  ```bash
  az network vnet subnet create \
  --name $masterSubnetName \
  --resource-group $vnetResourceGroup \
  --vnet-name $vnetName \
  --address-prefixes $masterSubnetIPAddress \
  --service-endpoints Microsoft.ContainerRegistry
  ```

  

- **Disable subnet private endpoint policies**

  ```bash
  az network vnet subnet update \
  --name $masterSubnetName \
  --resource-group $vnetResourceGroup \
  --vnet-name $vnetName \
  --disable-private-link-service-network-policies true
  ```

  

- **Create Service Principal for ARO cluster**

  ```bash
  az ad sp create-for-rbac --role Contributor -n $servicePrincipalName
  # Note down the response
  {
    "appId": "<client_id>",
    "displayName": "<display_name>",
    "name": "http://<display_name>",
    "password": "<client_secret>",
    "tenant": "<tenant_id>"
  }
  ```

  

- **Create the ARO Cluster (Public/Private)**

  ```bash
  az aro create \
    --resource-group $resourceGroup \
    --location $location \
    --name $clusterName \
    --vnet $vnetName \
    --master-subnet $masterSubnetName \
    --worker-subnet $workerSubnetName \
    --apiserver-visibility $clusterType \
    --ingress-visibility $clusterType \
    --worker-count $workerCount \
    --client-id "<client_id>" \
    --client-secret "<client_secret>" \
    --pull-secret @"/path/to/pull-secret.txt"
  ```

  

- **ARO cluster details**

  - These info would be needed while managing the cluster

  ```bash
  creds=$(az aro list-credentials -n $clusterName -g $resourceGroup)
  domain=$(az aro show -n $clusterName -g $resourceGroup --query clusterProfile.domain -o tsv)
  location=$(az aro show -n $clusterName -g $resourceGroup --query location -o tsv)
  apiServer=$(az aro show -n $clusterName -g $resourceGroup --query apiserverProfile.url -o tsv)
  webConsole=$(az aro show -n $clusterName -g $resourceGroup --query consoleProfile.url -o tsv)
  
  echo $creds
  {
      "kubeadminusername": <user_name>,
      "kubeadminpassword": <password>
  
  }
  ```

  

- **Issuer URL -** 

  - This is to be used during Azure AD integration

  ```bash
  oauthCallbackURL=https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AAD
  ```

  

- **kube:admin login - a temporary cluster admin**

  ```bash
  oc login $apiServer -u <user_name> -p <password>
  ```

  

- **Configure Azure AD for RBAC**

  - Refer this link for step-by-step guide - https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui

  ```bash
  # Ask each user to login with AAD credentials as described in the above link
  # kube:admin user would see all users as they login from their respective console(s) for the first time
  
  # Goto User Management -> Groups in Web console
  # Create Groups using web console with these users - at least 3 (recommended) - clusteradmins, architects, developers
  ```

  

- **RBAC**

  ```bash
  # Refer to RBAC folder in source
  
  # Deploy Cluster Admins
  oc apply -f "path/to/cluster_admin_rbac_file_name" (specify group name as clusteradmins)
  
  # Deploy Cluster Managers
  oc apply -f "path/to/cluster_managers_rbac_file_name" (specify group name as architects)
  
  # Deploy Developers
  oc apply -f "path/to/developers_rbac_file_name" (specify group name as developers)
  
  # Someone from clusteradmins group can now login using AAD credentials
  # Perform all subsequent cluster configurations
  ```

  

- **Network Policy (*East-West Traffic*)**

  1. NetPol folder in source repo would contain sample *Network Policy* file.This can be modified to create more specific policies

  2. Define Ingress policy for each micro service (aka tyoe of PODs)

  3. Define Egress policy for each micro service (aka tyoe of PODs)

  4. Include any socaial IPs to be allowed

  5. Exclude any IPs to Disallowed

  6. Define Egress Firewall Network policy to restrict Pods accessing external links

     

  ```bash
  # Decide on the communication within cluster
  
  # Refer to Netpol folder in source
  
  # Define Ingress and Egress of each Pod, Namespace with aprropriate access (specific to application needs)
  
  # Deploy a sample network policy for reference
  oc apply -f "path/to/netpol_file_name"
  
  # Define Egress Firewall Network Policy
  # This is to make sure what external links the Pods within the cluster can access
  # Deploy a sample Egress network policy for reference
  oc apply -f "path/to/egress_netpol_file_name"
  
  ```

- **Secrets**

  - Create All Secrets needed by the micro services
  - Majorly Docker Secrets, Storage Secrets, DB Secrets etc.
  - This can be done using oc command line Or through Web Console



## Day-2 Activities

### Deployment Phase

- **Create Projects/Namespaces - *Dev, QA, Staging***

  ```bash
  $projectName = "<place_holder>" (Same as namespace in k8s)
  # e.g. aro-workshop-dev
  ```
  
  
  
- **Create a Sample app***

  ```bash
  #Deploy nginx server (for testing and health probe)
  oc new-app nginxinc/nginx-unprivileged
  ```

  

- **Deploy MongoDB**

  ```bash
  oc process openshift//mongodb-persistent -p MONGODB_USER=ratingsuser -p MONGODB_PASSWORD=ratingspassword -p MONGODB_DATABASE=ratingsdb -p MONGODB_ADMIN_PASSWORD=ratingspassword | oc create -f -
  ```

  

- **Deploy RatingsWebARO**

  ```bash
  oc new-app https://github.com/monojit18/RatingsWebARO/ --context-dir=/RatingsWeb/Source
  
  # Go to Deployments in Web Console
  # Select ratingswebaro deployment entry
  # Select Environments -> Add an entry
  API = http://ratingsapiaro.aro-workshop-dev.svc.cluster.local
  ```

  

- **Deploy RatingsApiARO**

  ```bash
  oc new-app https://github.com/monojit18/RatingsApiARO/ --context-dir=/RatingsApi/Source
  
  # Go to Deployments in Web Console
  # Select ratingsapiaro deployment entry
  # Select Environments -> Add an entry
  MONGODB_URI = mongodb://ratingsuser:ratingspassword@mongodb:27017/ratingsdb
  ```

  

- **Test the entire flow**

  ```bash
  oc expose svc/ratingswebaro
  
  # Go to Web console
  # Select Routes
  # Select the newly generated route and test the app flow
  ```

  

- **Hands-on-workshop**

  ```http
  https://aroworkshop.io/
  ```

  

















