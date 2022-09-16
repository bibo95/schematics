###############################################################################
# IBM Confidential
# OCO Source Materials
# IBM Cloud Schematics
# (C) Copyright IBM Corp. 2022 All Rights Reserved.
# The source code for this program is not  published or otherwise divested of
# its trade secrets, irrespective of what has been deposited with
# the U.S. Copyright Office.
###############################################################################

#DONOT EDIT THIS FILE UNLESS YOU ARE SURE WHAT YOU ARE DOING

locals {
  #"IAM endpoint url"
  iam_url = "https://private.iam.cloud.ibm.com"
  #IAM compatmode (false for stage/prod)
  iam_compatmode = "false"
  #Schematics endpoint url (optional: private CSE or VPE)
  schematics_endpoint = "https://private-${var.schematics_endpoint_location}.schematics.cloud.ibm.com"
  #Schematics agent jobrunner image ID
  schematics_jobrunner_image = "icr.io/schematics-remote/schematics-job-runner:eb8ca280-179"
  #Schematics agent job12 image ID
  schematics_runtime_job_image = "icr.io/schematics-remote/schematics-agent-ws-job-20220704:60824f4e-276"
  #Schematics agent ansible image ID
  schematics_runtime_ansible_job_image = "us.icr.io/schematics/schematics-ansible-job:b164f614-171"
  #Schematics agent adapter image ID
  schematics_runtime_adapter_job_image = "us.icr.io/schematics/schematics-data-adapter:48537ed2-62"
  #schematics_sandbox_image
  schematics_sandbox_image = "icr.io/schematics-remote/schematics-sandbox:9bdc3645-283"
  #Schematics environment (dev|stage|prod)
  schematics_environment = "Prod"
}

locals {
  #Config dir where the cluster config will be downloaded
  config_dir = "/tmp"
  #Define namespaces
  namespaces = {
    schematics_job_runtime = "schematics-job-runtime"
    schematics_sandbox     = "schematics-sandbox"
    schematics_runtime     = "schematics-runtime"
    logdna_agent           = "schematics-ibm-observe"
  }
}