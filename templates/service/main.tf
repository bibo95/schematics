###############################################################################
# IBM Confidential
# OCO Source Materials
# IBM Cloud Schematics
# (C) Copyright IBM Corp. 2022 All Rights Reserved.
# The source code for this program is not  published or otherwise divested of
# its trade secrets, irrespective of what has been deposited with
# the U.S. Copyright Office.
###############################################################################


##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.location
  ibmcloud_timeout = 60
}

##############################################################################


##############################################################################
# Resource Group where VPC is created
##############################################################################

data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}
##############################################################################
# Resource Group where LOGDNA is created
##############################################################################

data "ibm_resource_group" "resource_group_logdna" {
  name = var.resource_group_name_logdna
}


##############################################################################
# Kubetnetes provider setup
##############################################################################

data "ibm_container_cluster_config" "config" {
  cluster_name_id   = var.cluster_id
  config_dir        = local.config_dir
  resource_group_id = data.ibm_resource_group.resource_group.id
}

provider "kubernetes" {
  config_path = data.ibm_container_cluster_config.config.config_file_path
}

##############################################################################

##############################################################################
# create all the requires namespaces for the services
##############################################################################

resource "kubernetes_namespace" "namespace" {
  for_each = local.namespaces
  metadata {
    labels = {
      mylabel = each.value
    }
    name = each.value
  }
}

module "network_policies" {
  source                 = "./network_policies"
  schematics_job_runtime = local.namespaces.schematics_job_runtime
  schematics_sandbox     = local.namespaces.schematics_sandbox
  schematics_runtime     = local.namespaces.schematics_runtime
  depends_on             = [kubernetes_deployment.runtime_job, kubernetes_deployment.jobrunner, kubernetes_deployment.sandbox]
}


##############################################################################
