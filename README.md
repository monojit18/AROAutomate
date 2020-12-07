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

        **<u>/21, 22</u>** for Dev/UAT and **<u>/18, /20</u>** for Prod id safe to choose. *If Address space is an issue then Kubenet*. This should be a dedicated subnet for AKS cluster.

        The question that should debated at this stage are -

        - How many micro-services approximately to be deployed (*now* and *in future*)
        - What would the minimum and maximum no. of replicas for each
        - How much *CPU* and *Memory* that each micro-services could consume approximately
        - And based on all these –
          - What is Size of each *Node* (VM) i.e how many *Cores of CPU* and how much *GB of Runtime Memory*
          - how many *Nodes* (VMs) that the cluster could expect (*initially and when scaled up?*) – basically *minimum* and *maximum* no. of such *Nodes*
        - Finally *maximum* number of pods or app replicas you want in each *Node* – Ideally whatever be the size of the *Node*, this value should not go beyond 40-50; not an hard and fast rule but with standard VM sizes like 8 Core 16 GB, 40-50 *Pods* per *Node* is good enough Based on all these info, let us try to define a formulae to decide what would be the address space of VNET and Subnet for AKS.

        Let us assume,

        **Np** = Max. Number of Pods in each Node (Ideally should not be more ethan 40-50)

        **Nd** = Max. Number of Nodes possible (approx.)

        Then the total no. of addresses that you would need in AKS Subnet = ***(Np \* (Nd + 1) + Np)\***

        *+1 for reserved IP by system for each Node*

        *+Np for additional IPs you might need while Upgrade* – normally K8s system will pull down one Node at a time, transfer all workloads to another Node and then upgrade the previous Node

        It is advisable to keep some more in buffer based on workloads and other unforeseen situations

        What we have seen, for high end workloads, ideally for a *DEV-UAT* cluster, we should go with **/21 or /22** which means around 2k or 1k *Nodes*.

        *PROD* cluster should have a bit more like **/18 or /20** which means around 16k or 4k *Nodes*

      - **APIM subnet** (*Optional*) - One dedicated subnet for APIM. Two options are there - External VNET or Internal VNET.

        In case of *Internal* - the endpoint is completely private.

        In cade of *External* - the ingress to VNET is allowed by default and hence a proper NSG has to be added to control ingress access only from *Application Gateway*

        The address

        - *Same VNET or Separate VNET*? If one APIM across entire org then should be in a separate VNET and then peering with AKS VNET
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
        - ARO Subnet outbound would always use the public *Standard LoadBalancer* created during Cluster creatiopn process. To change that behaviour - add appripriate outbound rules and anyone of the following
          - Nat Gateway associated with ARO subnet
          - UDR through a Firewall Subnet
          - Forcing communication directly through web corporate proxy - this needs some amount scripting. Setting *http_proxy* or *https_proxy* can be deployed as a *Daemonset* on every AKS cluster node and force Nodes to send raffic through proxy

### Plan Communication to Azure Services

- **Private/Service Endpopints**

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

- ### **Folder Structure** - 

  - **Deployments**

    - 


  

  ## Day-2 Activities

  ### Cluster Hardening

  (*Associted Roles* -  **Architects, Managers, Developers(?)**)

  - **Network Policy** (*East-West Traffic*)

    1. NetPol folder under YAMLs folder (above) would contain sample Network Policy file.This can be modified crested more specific policies

    2. Define Ingress policy for each micro service (aka tyoe of PODs)

    3. Define Egress policy for each micro service (aka tyoe of PODs)

    4. Include any socaial IPs to be allowed

    5. Exclude any IPs to Disallowed

       

  - **Secrets**

    - Create All Secrets needed by the micro services

    - Majorly Docker Secrets, Storage Secrets, DB Secrets etc.

      

  - **Azure Policy**

    1. Go to Azure Portal and Select Policy
    2. Filter by Kubernetes keyworkd
    3. Add All relevant built-in policies on the cluster

  

  

  

  

  







