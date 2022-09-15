###############################################################################
# IBM Confidential
# OCO Source Materials
# IBM Cloud Schematics
# (C) Copyright IBM Corp. 2022 All Rights Reserved.
# The source code for this program is not  published or otherwise divested of
# its trade secrets, irrespective of what has been deposited with
# the U.S. Copyright Office.
###############################################################################

###############################################################################
# IAM TRUSTED PROFILE
###############################################################################

resource "ibm_iam_trusted_profile" "iam_trusted_profile" {
  name = "${var.agent_name}-profile"
  description = "Trusted profile for agent ${var.agent_name}"
}

data "ibm_container_vpc_cluster" "cluster" {
  cluster_name_id = var.cluster_id
}


resource "ibm_iam_trusted_profile_link" "iam_trusted_profile_link" {
  profile_id = ibm_iam_trusted_profile.iam_trusted_profile.id
  cr_type    = "IKS_SA"
  link {
    crn       = data.ibm_container_vpc_cluster.cluster.resource_crn
    namespace = "schematics-job-runtime"
    name      = "default"
  }
  name = "link"
}


resource "ibm_iam_trusted_profile_policy" "policy" {
  profile_id = ibm_iam_trusted_profile.iam_trusted_profile.id
  roles      = ["Operator"]

  resources {
    service = "schematics"
   
  }
}

resource "ibm_iam_trusted_profile_policy" "policy_1" {
  profile_id = ibm_iam_trusted_profile.iam_trusted_profile.id
  roles      = ["Reader"]


  resource_attributes {
    name     = "resourceGroupId"
    value    = data.ibm_resource_group.resource_group.id
  }
}

resource "ibm_iam_trusted_profile_policy" "policy_2" {
  profile_id = ibm_iam_trusted_profile.iam_trusted_profile.id
  roles      = ["Viewer"]

  resources {
    resource_type = "resource-group"
    resource      = data.ibm_resource_group.resource_group.id
  }
}