# schematics-agents-CLI

Use ibmcloud schematics CLI to create workspace and upload agent tar files.

## Create Agent Infrastructure Workspace

Use create_agent_infra_workspace.json with ibmcloud schematics cli to create workspace for infrastructure. Edit the json to update the inputs.

#### Inputs

| name | description | type | required | default | sensitive |
| ---------- | -------- | -------------- | ---------- | ----------- | ----------- |
| agent_prefix | You will use this prefix, for `vpc`, `cluster`, and  `observability`. (Maximum length 27 chars) |  |  | my-project |  |
| location | Location of the Agent infrastructure.  Note: For Beta, the Agent must be deployed in a freshly provisioned `VPC`, `IKS Cluster`, `Log Analysis` instances. |  |  | `us-south` |  |
| resource_group_name | Name of resource group used where Agent infrastructure was provisioned. | string | &check; | |  |
| tags | A list of tags for the Agent infrastructure | list(string) | | my-project:agent | |

#### Example

```
ibmcloud schematics workspace create  new --file create_agent_infra_workspace.json 
```

## Create Agent Services Workspace

Use create_agent_service_workspace.json with ibmcloud schematics cli to deploy services on the provisioned Agent Infrastructure.  Edit the json to update the inputs.

| name | description | type | required | default | sensitive |
| ---------- | -------- | -------------- | ---------- | ----------- | ----------- |
| ibmcloud_api_key | The IBM Cloud API Key used to provision the schematics Agent infrastructure resources. If not provided, then resources will be provisioned in currently logged in user account. | string | | | &check; |
| agent_name | Name of the agent. | string | | my-project | |
| location| Location of the agent services.  It must be the same as the agent infrastructure/cluster location. | string | | us-south | |
| resource_group_name | Name of resource group used where agent infrastructure was provisioned. | string | &check; | | |
| profile_id | The IBM Cloud IAM Trusted Profile ID which provides authorization for agents to process jobs. More info can be found [here](https://cloud.ibm.com/docs/account?topic=account-create-trusted-profile&interface=ui) | string | &check; | | &check; |
| schematics_endpoint_location | Location of the schematics endpoint. This location is used to connect your agent with schematics service. The valid locations are us/eu/us-south/us-east/eu-de/eu-gb | string | | `us-south` | |
| cluster_id | ID of the cluster used to run the agent service. | string | &check; | | |
| logdna_name | Name of the IBM Log Analysis service instance, used to send the agent logs. | string | &check; | | |


#### Example

```
ibmcloud schematics workspace create  new --file create_agent_service_workspace.json 
```

## Next Steps

Download the schematics-agents release to your local system.
- From your terminal extract the schematics-agents.tgz
- The templates as TAR files should now be available as
   - The `agent-infrastructure-templates.tar` for setting up the VPC, IKS cluster, and LogDNA services infrastructure. 
   - The `agent-service-templates.tar` to deploy the Agent service into your infrastructure. 
- Use ibmcloud schematics cli to upload the tar files to respective workspace
```
ex: 
ibmcloud schematics workspace upload  --id us-east.workspace.schematics-remote-service-workspace.f3c5bfe2  --file ./agent-service-templates.tar -tid 9bfe4530-cfb2-41
```