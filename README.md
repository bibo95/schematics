# Schematics Agents

The IBM Cloud Schematics Agents extends Schematics ability to reach your private, or on-premises, infrastructure. Integrate the Schematics Agents running in your private network to the IBM Cloud Schematics service to provision, configure, and operate your private or on-premise cloud cluster resources without any time, network, or software restrictions.

This Agent repository helps you to provision the infrastructure required for an Agent and deploys the services on the provisioned infrastructure.

## Table of Contents

1. [Prerequisites](##Prerequisites)
2. [Agents deployment](##Agents-Deployment)
3. [Using tar files](##Using-Tar-Files)
4. [Infrastructure](##Infrastructure)
5. [Service](##Service)
6. [Terraform versions](##Terraform-Versions)
7. [Inputs](##Inputs)
8. [Outputs](##Outputs)
9. [Next Steps](##Next-Steps)

## Prerequisites

1. Make sure that you are [assigned the correct permissions](https://cloud.ibm.com/docs/schematics?topic=schematics-access) to create the workspace and deploy resources.
2. Make sure that you have the [required IBM Cloud IAM permissions](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-user-permissions-for-vpc-resources) to create and work with VPC infrastructure and you are [assigned the correct permissions](https://cloud.ibm.com/docs/schematics?topic=schematics-access) to create the workspace and deploy the resources.
3. Make sure that you have the [required IBM Cloud IAM permissions](https://cloud.ibm.com/docs/containers?topic=containers-access_reference) to create and work with IBM Cloud Cluster.
4. Make sure that you have the [required IBM Cloud IAM permissions](https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-iam) to create and work with IBM Log Analysis.
5. Make sure that you have the [required IBM Cloud IAM permissions](https://cloud.ibm.com/docs/activity-tracker?topic=activity-tracker-iam) to create and work with IBM Activity tracker.

## Terraform versions

|  **Name**                  | **Version** |
|  --------------------------| -------------|
|  terraform                 | ~> 1.0 |
|  terraform_provider_ibm    | ~> 1.42 |

## Agents deployment

This repository has `.tf` configuration for the deployment of Agent infrastructure and service.

```text
├── templates
|   └── infrastructure
|   └── service
```

## Using tar files

The release contains the solution templates in the form of `tar` files to install the `Agent infrastructure` and deploy the `Agent service`. Perform following steps to use the `tar` file.

- Download the schematics-agents release to your local system.
- From your terminal extract the content of `schematics-agents.tgz`
- The templates as TAR files should now be available as
   - The `agent-infrastructure-templates.tar` for setting up the VPC, IKS cluster, and LogDNA services infrastructure. 
   - The `agent-service-templates.tar` to deploy the Agent service into your infrastructure.

## Infrastructure
    
The `agent-infrastructure-templates.tar` is a Terraform configuration archive files which provisions Agent infrastructure on IBM Cloud. A collection of following services are provisioned.
- VPC
- IBM Kubernetes cluster
- IBM Log Analysis
- Activity Tracker

Click [here](https://cloud.ibm.com/docs/schematics?topic=schematics-agents-setup&interface=ui#agents-setup-infra-ui) to use the Agent infrastructure `tar` file. Link this repository to the Schematics Workspace and run `Generate Plan` and `Apply Plan` to create the Agent infrastructure.
    
## Service

The `agent-service-templates.tar` contains Terraform configuration which deploys Agent services on infrastructure. A collection of Agent related microservices deployed on the Agent infrastructure. It is composed of the following microservices
    - Sandbox
    - runtime-job
    - Job runner
    
Click [here](https://cloud.ibm.com/docs/schematics?topic=schematics-agents-setup&interface=ui#agents-setup-svc) to use the Agent service `tar` file. Link this repository to the Schematics Workspace and run `Generate Plan` and `Apply Plan` to deploy the Agent services the Agent infrastructure.

## Inputs

| name | description | type | required | default | sensitive |
| ---------- | -------- | -------------- | ---------- | ----------- | ----------- |
| agent_prefix | You will use this prefix, for `vpc`, `cluster`, and  `observability`. (Maximum length 27 chars) |  |  | my-project |  |
| location | Location of the Agent infrastructure.  Note: For Beta, the Agent must be deployed in a freshly provisioned `VPC`, `IKS Cluster`, `Log Analysis` instances. |  |  | `us-south` |  |
| tags | A list of tags for the Agent infrastructure | list(string) | | my-project:agent | |
| ibmcloud_api_key | The IBM Cloud API Key used to provision the schematics Agent infrastructure resources. If not provided, then resources will be provisioned in currently logged in user account. | string | | | &check; |
| agent_name | Name of the agent. | string | | my-project | |
| location| Location of the agent services.  It must be the same as the agent infrastructure/cluster location. | string | | us-south | |
| profile_id | The IBM Cloud IAM Trusted Profile ID which provides authorization for agents to process jobs. More info can be found [here](https://cloud.ibm.com/docs/account?topic=account-create-trusted-profile&interface=ui) | string | &check; | | &check; |
| schematics_endpoint_location | Location of the schematics endpoint. This location is used to connect your agent with schematics service. The valid locations are us/eu/us-south/us-east/eu-de/eu-gb | string | | `us-south` | |
| cluster_id | ID of the cluster used to run the agent service. | string | &check; | | |
| logdna_name | Name of the IBM Log Analysis service instance, used to send the agent logs. | string | &check; | | |

## Outputs

- Click [here](https://cloud.ibm.com/docs/schematics?topic=schematics-agents-setup&interface=ui#agents-setup-infra-output) to view the Agent infrastructure workspace setup. 
- Click [here](https://cloud.ibm.com/docs/schematics?topic=schematics-agents-setup&interface=ui#agents-setup-svc) to view the outcome of deploying an Agent service workspace.

## Next Steps

You have completed the Agent connection to your Schematics service instance.
   - Now, you need to [register your Agent](https://cloud.ibm.com/docs/schematics?topic=schematics-register-agent&interface=ui#register-ui) service with your Schematics service instance.
   - And, to use an Agent, you need to [bind the Agent](https://cloud.ibm.com/docs/schematics?topic=schematics-using-agent&interface=ui#steps-bind-new-wks) to new Workspace or existing workspace, in order to run the IaC automation in your cluster.
